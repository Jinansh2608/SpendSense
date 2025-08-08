from flask import Flask, request, jsonify
from flask_cors import CORS
from sentence_transformers import SentenceTransformer
import joblib
import psycopg2
from psycopg2.extras import RealDictCursor
from datetime import datetime
import logging
import os
import re

# === Setup Logging ===
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# === Load Environment Variables ===
DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'port': os.getenv('DB_PORT', '5432'),
    'dbname': os.getenv('DB_NAME', 'Spendsense'),
    'user': os.getenv('DB_USER', 'postgres'),
    'password': os.getenv('DB_PASSWORD', 'toor'),
}

# === Initialize Flask App ===
app = Flask(__name__)
CORS(app)

# === Load ML Model & Encoder ===
logger.info("🔄 Loading ML model and encoder...")
classifier = joblib.load("models/category_classifier.pkl")
label_encoder = joblib.load("models/label_encoder.pkl")
sentence_model = SentenceTransformer("all-MiniLM-L6-v2")
logger.info("✅ ML components loaded.")

# === DB Connection Function ===
def get_db_connection():
    return psycopg2.connect(
        host=DB_CONFIG['host'],
        port=DB_CONFIG['port'],
        dbname=DB_CONFIG['dbname'],
        user=DB_CONFIG['user'],
        password=DB_CONFIG['password'],
        cursor_factory=RealDictCursor
    )

# === Create Table If Not Exists ===
def init_db():
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("""
            CREATE TABLE IF NOT EXISTS sms_records (
                id SERIAL PRIMARY KEY,
                uid TEXT NOT NULL,
                sms TEXT NOT NULL,
                sender TEXT,
                category TEXT NOT NULL,
                amount TEXT,
                txn_type TEXT,
                mode TEXT,
                ref_no TEXT,
                account TEXT,
                date TEXT,
                balance TEXT,
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

# === Simple SMS Parser ===
def parse_sms(sms: str):
    data = {
        "amount": None,
        "txn_type": None,
        "mode": None,
        "ref_no": None,
        "account": None,
        "date": None,
        "balance": None
    }

    # Patterns
    amount_match = re.search(r'(?i)(?:Rs\.?|INR)[\s]*([\d,]+\.?\d*)', sms)
    ref_match = re.search(r'(?i)Ref(?:erence)?(?: No)?\.?\s*[:\-]?\s*([A-Za-z0-9]+)', sms)
    account_match = re.search(r'(?i)(?:A/c(?:\s+No)?(?:\s*XX)?\s*)(\w+)', sms)
    date_match = re.search(r'(\d{2,4}[/-]\d{1,2}[/-]\d{1,4})', sms)
    balance_match = re.search(r'(?i)(?:bal|balance)[\s:]*Rs\.?\s*([\d,]+\.?\d*)', sms)

    if amount_match:
        data['amount'] = amount_match.group(1).replace(',', '')
    if ref_match:
        data['ref_no'] = ref_match.group(1)
    if account_match:
        data['account'] = account_match.group(1)
    if date_match:
        data['date'] = date_match.group(1)
    if balance_match:
        data['balance'] = balance_match.group(1).replace(',', '')

    # Guess txn_type
    if re.search(r'(?i)debited|spent|withdrawn|deducted', sms):
        data['txn_type'] = 'debit'
    elif re.search(r'(?i)credited|received|deposited', sms):
        data['txn_type'] = 'credit'

    # Guess mode
    if re.search(r'(?i)UPI|GPay|PhonePe|Paytm', sms):
        data['mode'] = 'UPI'
    elif re.search(r'(?i)ATM|Cash', sms):
        data['mode'] = 'ATM'
    elif re.search(r'(?i)NEFT|IMPS|RTGS|Net Banking', sms):
        data['mode'] = 'NetBanking'

    return data

# === Prediction + Storage Endpoint ===
@app.route("/predict-bulk", methods=["POST"])
def predict_bulk():
    data = request.get_json()

    if not data or "messages" not in data or "uid" not in data:
        return jsonify({"error": "Missing 'messages' or 'uid' field"}), 400

    messages = data["messages"]
    uid = data["uid"]

    if not isinstance(messages, list) or not isinstance(uid, str):
        return jsonify({"error": "'messages' must be a list and 'uid' must be a string"}), 400

    try:
        embeddings = sentence_model.encode([msg['sms'] for msg in messages])
        predictions = classifier.predict(embeddings)
        categories = label_encoder.inverse_transform(predictions)

        conn = get_db_connection()
        cur = conn.cursor()
        timestamp = datetime.now()

        result = []
        for msg_obj, category in zip(messages, categories):
            sms = msg_obj.get("sms")
            sender = msg_obj.get("sender")
            parsed = parse_sms(sms)

            values = (
                uid, sms, sender, category,
                parsed.get("amount"), parsed.get("txn_type"), parsed.get("mode"),
                parsed.get("ref_no"), parsed.get("account"), parsed.get("date"),
                parsed.get("balance"), timestamp
            )

            cur.execute("""
                INSERT INTO sms_records (uid, sms, sender, category, amount, txn_type, mode, ref_no, account, date, balance, created_at)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, values)

            result.append({
                "sms": sms,
                "sender": sender,
                "category": category,
                "amount": parsed.get("amount"),
                "txn_type": parsed.get("txn_type"),
                "mode": parsed.get("mode"),
                "ref_no": parsed.get("ref_no"),
                "account": parsed.get("account"),
                "date": parsed.get("date"),
                "balance": parsed.get("balance"),
                "timestamp": timestamp.isoformat(),
                "uid": uid
            })

        conn.commit()
        cur.close()
        conn.close()

        return jsonify(result), 200

    except Exception as e:
        logger.error(f"❌ Error in prediction: {e}")
        return jsonify({"error": str(e)}), 500

# === Fetch Messages by UID ===
@app.route("/records/<uid>", methods=["GET"])
def get_user_records(uid):
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("""
            SELECT sms, sender, category, amount, txn_type, mode, ref_no, account, date, balance, created_at 
            FROM sms_records 
            WHERE uid = %s 
            ORDER BY created_at DESC
        """, (uid,))
        records = cur.fetchall()
        cur.close()
        conn.close()
        return jsonify(records), 200

    except Exception as e:
        logger.error(f"❌ Error fetching records: {e}")
        return jsonify({"error": str(e)}), 500

# === Health Check ===
@app.route("/", methods=["GET"])
def home():
    return "✅ SpendSense Server is running!"

# === Run Server (only for local dev) ===
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=False)