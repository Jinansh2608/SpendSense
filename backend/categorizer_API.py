from flask import Flask, request, jsonify, Blueprint
from flask_cors import CORS
import psycopg2
from psycopg2.extras import RealDictCursor
from psycopg2.pool import SimpleConnectionPool
import logging
import os
import re
import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry
from dotenv import load_dotenv
from time import sleep
from decimal import Decimal
from datetime import datetime, date
from typing import Any, Dict, List, Optional

# === Load Environment Variables ===
load_dotenv()

# === Logging ===
LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO").upper()
logging.basicConfig(level=LOG_LEVEL, format="%(asctime)s %(levelname)s %(name)s: %(message)s")
logger = logging.getLogger("spendsense.api")

# === Flask App ===
app = Flask(__name__)

# CORS Configuration
CORS_ORIGINS = [o.strip() for o in os.getenv("CORS_ORIGINS", "").split(",") if o.strip()]
if CORS_ORIGINS:
    CORS(app, resources={r"/*": {"origins": CORS_ORIGINS}})
else:
    CORS(app)

# === Config ===
DB_CONFIG = {
    "host": os.getenv("DB_HOST"),
    "port": os.getenv("DB_PORT", "5432"),
    "dbname": os.getenv("DB_NAME"),
    "user": os.getenv("DB_USER"),
    "password": os.getenv("DB_PASSWORD"),
}

_missing = [k for k, v in DB_CONFIG.items() if not v]
if _missing:
    logger.warning(f"⚠️ Missing DB env vars: {', '.join(_missing)}")

HUGGINGFACE_API_KEY = os.getenv("HF_API_KEY")
HUGGINGFACE_MODEL = os.getenv("HF_MODEL", "facebook/bart-large-mnli")
HF_API_URL = f"https://api-inference.huggingface.co/models/{HUGGINGFACE_MODEL}"

MAX_LIMIT = int(os.getenv("MAX_LIMIT", "200"))
DEFAULT_LIMIT = int(os.getenv("DEFAULT_LIMIT", "50"))

# === HTTP Session for HuggingFace ===
def build_http_session() -> requests.Session:
    session = requests.Session()
    retries = Retry(total=3, backoff_factor=0.5, status_forcelist=(429, 500, 502, 503, 504))
    adapter = HTTPAdapter(max_retries=retries)
    session.mount("https://", adapter)
    session.mount("http://", adapter)
    return session

http = build_http_session()

# === DB Connection Pool ===
POOL_MIN = int(os.getenv("DB_POOL_MIN", "1"))
POOL_MAX = int(os.getenv("DB_POOL_MAX", "10"))
_db_pool: Optional[SimpleConnectionPool] = None

def init_pool():
    global _db_pool
    if _db_pool is None:
        _db_pool = SimpleConnectionPool(POOL_MIN, POOL_MAX, **DB_CONFIG)
        logger.info(f"✅ DB pool initialized (min={POOL_MIN}, max={POOL_MAX})")

def get_db_connection():
    if _db_pool is None:
        init_pool()
    return _db_pool.getconn()

def put_db_connection(conn):
    if _db_pool and conn:
        _db_pool.putconn(conn)

# === Initialize DB ===
def init_db():
    conn = None
    cur = None
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
                sender TEXT,
                created_at TIMESTAMP DEFAULT NOW()
            );
        """)
        conn.commit()
        logger.info("✅ Database initialized successfully.")
    except Exception as e:
        logger.error(f"❌ DB Init Failed: {e}")
        if conn:
            conn.rollback()
    finally:
        if cur: cur.close()
        if conn: put_db_connection(conn)

with app.app_context():
    init_db()

# === Helpers ===
def is_promotional(text: Optional[str]) -> bool:
    if not text:
        return True
    text_lower = text.lower()
    promo_keywords = ["insurance", "loan offer", "apply now", "limited period offer", "download app", "sale", "discount", "emi offer"]
    txn_keywords = ["debited", "credited", "withdrawn", "payment", "transfer", "txn", "transaction", "purchase"]
    if any(word in text_lower for word in txn_keywords):
        return False
    if any(word in text_lower for word in promo_keywords):
        return True
    return False

def parse_sms(sms: str) -> Dict[str, Optional[str]]:
    if not sms:
        return {}
    data = {"amount": None, "txn_type": None, "mode": None, "ref_no": None, "account": None, "date": None, "balance": None}
    amount_match = re.search(r"(?i)(?:INR|Rs\.?|₹)\s*([\d,]+\.?\d*)", sms)
    if amount_match: data["amount"] = amount_match.group(1).replace(",", "")
    ref_match = re.search(r"(?i)(?:Ref(?:erence)?(?:\s*No)?\.?)\s*[:\-]?\s*([A-Za-z0-9\-_/]+)", sms)
    if ref_match: data["ref_no"] = ref_match.group(1)
    account_match = re.search(r"(?i)(?:A/c(?:\s*XX)?\s*)(\d+)", sms)
    if account_match: data["account"] = account_match.group(1)
    date_match = re.search(r"(\d{1,2}[-/][A-Za-z]{3}[-/]\d{2,4}|\d{1,2}[-/]\d{1,2}[-/]\d{2,4})", sms)
    if date_match: data["date"] = date_match.group(1)
    balance_match = re.search(r"(?i)(?:Avl Bal|balance)[\s:]*[₹Rs\.]*\s*([\d,]+\.?\d*)", sms)
    if balance_match: data["balance"] = balance_match.group(1).replace(",", "")
    if re.search(r"(?i)\b(debited?|spent|withdrawn|deducted|purchas(?:e|ed))\b", sms): data["txn_type"] = "Debit"
    elif re.search(r"(?i)\b(credited?|received|deposited|refunded?)\b", sms): data["txn_type"] = "Credit"
    if re.search(r"(?i)\b(UPI|GPay|PhonePe|Paytm)\b", sms): data["mode"] = "UPI"
    elif re.search(r"(?i)\b(ATM|Cash)\b", sms): data["mode"] = "ATM"
    elif re.search(r"(?i)\b(NEFT|IMPS|RTGS|Net\s*Banking)\b", sms): data["mode"] = "NetBanking"
    return data

def classify_text(text: str) -> str:
    if is_promotional(text): return "Promotional"
    if not HUGGINGFACE_API_KEY: return fallback_category(text)
    headers = {"Authorization": f"Bearer {HUGGINGFACE_API_KEY}"}
    candidate_labels = ["UPI", "Bank Transfer", "ATM Withdrawal", "Card Payment", "Recharge", "Loan", "Salary"]
    payload = {"inputs": text, "parameters": {"candidate_labels": candidate_labels}}
    try:
        resp = http.post(HF_API_URL, headers=headers, json=payload, timeout=10)
        if resp.status_code == 200:
            result = resp.json()
            if isinstance(result, dict) and "labels" in result and result["labels"]:
                return result["labels"][0]
    except Exception as e:
        logger.error(f"HF request failed: {e}")
    sleep(0.5)
    return fallback_category(text)

def fallback_category(text: str) -> str:
    t = text.lower()
    if "upi" in t or "gpay" in t or "phonepe" in t or "paytm" in t: return "UPI"
    if "atm" in t or "cash" in t: return "ATM Withdrawal"
    if "credit" in t or "card" in t or "pos" in t or "online payment" in t: return "Card Payment"
    if "salary" in t or "payroll" in t: return "Salary"
    if "loan" in t or "emi" in t: return "Loan"
    if "recharge" in t or "topup" in t: return "Recharge"
    return "Bank Transfer"

def json_safe(val):
    if isinstance(val, Decimal): return float(val)
    if isinstance(val, datetime): return val.strftime("%Y-%m-%dT%H:%M:%SZ")
    return val

def clamp_limit(val): return max(1, min(int(val), MAX_LIMIT))

# === Blueprints ===
prediction_bp = Blueprint("prediction", __name__)
records_bp = Blueprint("records", __name__)
health_bp = Blueprint("health", __name__)

# === Prediction Route ===
@prediction_bp.route("/predict-bulk", methods=["POST"])
def predict_bulk():
    conn = None
    cur = None
    try:
        data = request.get_json(silent=True) or {}
        uid = data.get("uid")
        messages = data.get("messages", [])
        if not uid or not isinstance(messages, list):
            return jsonify({"status": "error", "message": "Invalid payload"}), 400

        conn = get_db_connection()
        cur = conn.cursor()
        timestamp = datetime.utcnow()

        results = []
        insert_values = []
        for msg in messages:
            sms = msg.get("sms") if isinstance(msg, dict) else str(msg)
            sender = msg.get("sender") if isinstance(msg, dict) else None
            if not sms or is_promotional(sms): continue
            parsed = parse_sms(sms)
            amount = float(parsed["amount"]) if parsed.get("amount") else None
            balance = float(parsed["balance"]) if parsed.get("balance") else None
            txn_type = parsed.get("txn_type")
            category = classify_text(sms)
            insert_values.append((uid, sms, category, amount, txn_type, parsed.get("mode"), parsed.get("ref_no"), parsed.get("account"), parsed.get("date"), balance, sender, timestamp))
            results.append({"uid": uid, "sms": sms, "sender": sender, "category": category, "amount": amount, "txn_type": txn_type, "mode": parsed.get("mode"), "ref_no": parsed.get("ref_no"), "account": parsed.get("account"), "date": parsed.get("date"), "balance": balance, "created_at": timestamp.strftime("%Y-%m-%dT%H:%M:%SZ")})
        if insert_values:
            cur.executemany("""INSERT INTO sms_records (uid, sms, category, amount, txn_type, mode, ref_no, account, date, balance, sender, created_at) VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)""", insert_values)
            conn.commit()
        return jsonify({"status": "success", "count": len(results), "data": results}), 200
    except Exception as e:
        logger.exception("Error in predict_bulk")
        if conn: conn.rollback()
        return jsonify({"status": "error", "message": "Internal Server Error"}), 500
    finally:
        if cur: cur.close()
        if conn: put_db_connection(conn)

# === Records Route ===
@records_bp.route("/records/<uid>", methods=["GET"])
def get_user_records(uid):
    conn = None
    cur = None
    try:
        limit = clamp_limit(request.args.get("limit", DEFAULT_LIMIT))
        offset = max(0, int(request.args.get("offset", 0)))
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("""SELECT id, uid, sms, category, amount, txn_type, mode, ref_no, account, date, balance, created_at FROM sms_records WHERE uid = %s ORDER BY created_at DESC LIMIT %s OFFSET %s""", (uid, limit, offset))
        rows = cur.fetchall()
        cur.execute("SELECT COUNT(*) FROM sms_records WHERE uid = %s", (uid,))
        total_count = cur.fetchone()["count"]
        data = [{k: json_safe(v) for k, v in row.items()} for row in rows]
        return jsonify({"status": "success", "total": total_count, "count": len(data), "limit": limit, "offset": offset, "data": data}), 200
    except Exception as e:
        logger.exception("Error fetching records")
        return jsonify({"status": "error", "message": "Internal Server Error"}), 500
    finally:
        if cur: cur.close()
        if conn: put_db_connection(conn)

# === Health Route ===
@health_bp.route("/", methods=["GET"])
def health_check():
    return jsonify({"status": "ok", "message": "✅ SpendSense Server is running!"})

# Register Blueprints
app.register_blueprint(prediction_bp)
app.register_blueprint(records_bp)
app.register_blueprint(health_bp)

@app.after_request
def set_security_headers(resp):
    resp.headers["X-Content-Type-Options"] = "nosniff"
    resp.headers["X-Frame-Options"] = "DENY"
    resp.headers["X-XSS-Protection"] = "1; mode=block"
    return resp

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)

