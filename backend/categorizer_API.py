from flask import Flask, request, jsonify
from flask_cors import CORS
import psycopg2
from psycopg2.extras import RealDictCursor
from datetime import datetime
import logging
import os
import re
import requests
from dotenv import load_dotenv
from time import sleep

# === Load Environment Variables ===
load_dotenv()

# === Logging ===
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# === Config ===
DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'port': os.getenv('DB_PORT', '5432'),
    'dbname': os.getenv('DB_NAME', 'Spendsense'),
    'user': os.getenv('DB_USER', 'postgres'),
    'password': os.getenv('DB_PASSWORD', 'toor'),
}

HUGGINGFACE_API_KEY = os.getenv('HF_API_KEY')
HUGGINGFACE_MODEL = os.getenv('HF_MODEL', 'facebook/bart-large-mnli')
HF_API_URL = f"https://api-inference.huggingface.co/models/{HUGGINGFACE_MODEL}"

# === Initialize Flask ===
app = Flask(__name__)
CORS(app)

# === DB Connection ===
def get_db_connection():
    return psycopg2.connect(
        host=DB_CONFIG['host'],
        port=DB_CONFIG['port'],
        dbname=DB_CONFIG['dbname'],
        user=DB_CONFIG['user'],
        password=DB_CONFIG['password'],
        cursor_factory=RealDictCursor
    )

# === Create Table if not exists ===
def init_db():
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("""
            CREATE TABLE IF NOT EXISTS sms_records (
                id SERIAL PRIMARY KEY,
                uid TEXT NOT NULL,
                sms TEXT NOT NULL,
                category TEXT NOT NULL,
                amount NUMERIC,
                txn_type TEXT,
                mode TEXT,
                ref_no TEXT,
                account TEXT,
                date TEXT,
                balance NUMERIC,
                created_at TIMESTAMP DEFAULT NOW()
            );
        """)
        conn.commit()
        cur.close()
        conn.close()
        logger.info("✅ Database initialized successfully.")
    except Exception as e:
        logger.error(f"❌ DB Init Failed: {e}")

with app.app_context():
    init_db()

# === Promotional Filter ===
def is_promotional(text):
    if not text:
        return True
    text_lower = text.lower()
    promo_keywords = ['insurance', 'loan offer', 'apply now', 'limited period offer']
    txn_keywords = ['debited', 'credited', 'withdrawn', 'payment', 'transfer', 'txn', 'transaction', 'purchase']

    if any(word in text_lower for word in txn_keywords):
        return False
    if any(word in text_lower for word in promo_keywords):
        return True
    return False

# === SMS Parser ===
def parse_sms(sms: str):
    if not sms:
        return {}

    data = {
        "amount": None,
        "txn_type": None,
        "mode": None,
        "ref_no": None,
        "account": None,
        "date": None,
        "balance": None
    }

    # Amount
    amount_match = re.search(r'(?i)(?:INR|Rs\.?|₹)\s*([\d,]+\.?\d*)', sms)
    if amount_match:
        data['amount'] = amount_match.group(1).replace(',', '')

    # Ref Number
    ref_match = re.search(r'(?i)(?:Ref(?:erence)?(?: No)?\.?)\s*[:\-]?\s*([A-Za-z0-9]+)', sms)
    if ref_match:
        data['ref_no'] = ref_match.group(1)

    # Account Number
    account_match = re.search(r'(?i)(?:A/c(?:\s*XX)?\s*)(\d+)', sms)
    if account_match:
        data['account'] = account_match.group(1)

    # Date
    date_match = re.search(r'(\d{1,2}[-/][A-Za-z]{3}[-/]\d{2,4})', sms)
    if date_match:
        data['date'] = date_match.group(1)

    # Balance
    balance_match = re.search(r'(?i)(?:Avl Bal|balance)[\s:]*[₹Rs\.]*\s*([\d,]+\.?\d*)', sms)
    if balance_match:
        data['balance'] = balance_match.group(1).replace(',', '')

    # Transaction Type
    if re.search(r'(?i)\b(debited?|spent|withdrawn|deducted|purchased?)\b', sms):
        data['txn_type'] = 'Debit'
    elif re.search(r'(?i)\b(credited?|received|deposited|refunded?)\b', sms):
        data['txn_type'] = 'Credit'

    # Mode
    if re.search(r'(?i)UPI|GPay|PhonePe|Paytm', sms):
        data['mode'] = 'UPI'
    elif re.search(r'(?i)ATM|Cash', sms):
        data['mode'] = 'ATM'
    elif re.search(r'(?i)NEFT|IMPS|RTGS|Net Banking', sms):
        data['mode'] = 'NetBanking'

    return data

# === Hugging Face Classification ===
def classify_text(text):
    if is_promotional(text):
        return "Promotional"

    candidate_labels = ["UPI", "Bank Transfer", "ATM Withdrawal", "Card Payment", "Recharge", "Loan", "Salary"]
    headers = {"Authorization": f"Bearer {HUGGINGFACE_API_KEY}"}
    payload = {"inputs": text, "parameters": {"candidate_labels": candidate_labels}}

    for attempt in range(3):  # retry
        try:
            response = requests.post(HF_API_URL, headers=headers, json=payload, timeout=10)
            if response.status_code == 200:
                result = response.json()
                if "labels" in result and result["labels"]:
                    return result["labels"][0]
            else:
                logger.warning(f"HF API Attempt {attempt+1} failed: {response.status_code}")
        except Exception as e:
            logger.error(f"❌ HF Classification Error (Attempt {attempt+1}): {e}")
        sleep(1)

    # Fallback
    if "upi" in text.lower():
        return "UPI"
    if "atm" in text.lower():
        return "ATM Withdrawal"
    if "credit" in text.lower() or "card" in text.lower():
        return "Card Payment"
    return "Bank Transfer"

# === Prediction + DB Storage ===
@app.route("/predict-bulk", methods=["POST"])
def predict_bulk():
    try:
        data = request.get_json()

        # Validate request body
        if not data or "messages" not in data or "uid" not in data:
            return jsonify({"status": "error", "message": "Missing 'messages' or 'uid'"}), 400

        uid = data["uid"]
        messages = data["messages"]

        if not isinstance(messages, list) or not messages:
            return jsonify({"status": "error", "message": "'messages' should be a non-empty list"}), 400

        conn = get_db_connection()
        cur = conn.cursor()
        timestamp = datetime.now()

        results = []
        insert_values = []

        for sms in messages:
            # ✅ Skip invalid or empty messages
            if not sms or not isinstance(sms, str):
                continue

            sms = sms.strip()
            if not sms:
                continue

            # ✅ Skip promotional but keep INR transactional
            if is_promotional(sms) and "INR" not in sms:
                continue

            # ✅ Classify message
            category = classify_text(sms)
            confidence = 1.0  # Placeholder since HF API confidence is not captured

            # ✅ Extract transaction details
            parsed = parse_sms(sms)

            amount = float(parsed["amount"]) if parsed.get("amount") else None
            balance = float(parsed["balance"]) if parsed.get("balance") else None

            # ✅ Prepare values for DB
            insert_values.append((
                uid, sms, category, amount,
                parsed.get("txn_type"), parsed.get("mode"),
                parsed.get("ref_no"), parsed.get("account"),
                parsed.get("date"), balance, timestamp
            ))

            # ✅ Add to result for API response
            results.append({
                "sms": sms,
                "category": category,
                "confidence": confidence,
                "amount": amount,
                "txn_type": parsed.get("txn_type"),
                "mode": parsed.get("mode"),
                "ref_no": parsed.get("ref_no"),
                "account": parsed.get("account"),
                "date": parsed.get("date"),
                "balance": balance,
                "timestamp": timestamp.isoformat(),
                "uid": uid
            })

        # ✅ Bulk insert for performance
        if insert_values:
            cur.executemany("""
                INSERT INTO sms_records 
                (uid, sms, category, amount, txn_type, mode, ref_no, account, date, balance, created_at)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, insert_values)

        conn.commit()
        cur.close()
        conn.close()

        return jsonify({"status": "success", "count": len(results), "data": results}), 200

    except Exception as e:
        logger.error(f"❌ Error in prediction: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

# === Fetch Records ===
# === Fetch Records ===
@app.route("/records/<uid>", methods=["GET"])
def get_user_records(uid):
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("""
            SELECT sms, category, amount, txn_type, mode, ref_no, account, date, balance, created_at 
            FROM sms_records 
            WHERE uid = %s 
            ORDER BY created_at DESC
        """, (uid,))
        
        rows = cur.fetchall()
        columns = [desc[0] for desc in cur.description]  # Get column names
        cur.close()
        conn.close()

        # Convert rows to list of dict
        records = [dict(zip(columns, row)) for row in rows]

        return jsonify({"status": "success", "count": len(records), "data": records}), 200

    except Exception as e:
        logger.error(f"❌ Error fetching records: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500



@app.route("/", methods=["GET"])
def home():
    return jsonify({"status": "ok", "message": "✅ SpendSense Server is running!"})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", 5000)), debug=False)
