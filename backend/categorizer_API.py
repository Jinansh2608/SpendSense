import json
import logging
import os
import re
import uuid
from datetime import datetime, date
from decimal import Decimal
from functools import wraps
from time import sleep
from typing import Any, Dict, List, Optional

import requests
from dotenv import load_dotenv
from flask import Flask, Blueprint, jsonify, request
from flask_cors import CORS
from psycopg2.extras import RealDictCursor
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

from database import get_db_connection, init_db, put_db_connection
from errors import register_error_handlers
from validation import (
    bill_parse_schema,
    bulk_prediction_schema,
    budget_schema,
    validate_payload,
)

# === Load Environment Variables ===
load_dotenv()

# === Logging ===
LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO").upper()
logging.basicConfig(
    level=LOG_LEVEL, format="%(asctime)s %(levelname)s %(name)s: %(message)s"
)
logger = logging.getLogger("spendsense.api")

# === Flask App ===
app = Flask(__name__)
register_error_handlers(app)

# === CORS Configuration ===
CORS_ORIGINS = [
    o.strip() for o in os.getenv("CORS_ORIGINS", "").split(",") if o.strip()
]
if CORS_ORIGINS:
    CORS(app, resources={r"/*": {"origins": CORS_ORIGINS}})
else:
    CORS(app)

# === Config ===
HUGGINGFACE_API_KEY = os.getenv("HF_API_KEY")
HUGGINGFACE_MODEL = os.getenv("HF_MODEL", "mistralai/Mixtral-8x7B-Instruct-v0.1")
HF_API_URL = f"https://api-inference.huggingface.co/models/{HUGGINGFACE_MODEL}"

MAX_LIMIT = int(os.getenv("MAX_LIMIT", "200"))
DEFAULT_LIMIT = int(os.getenv("DEFAULT_LIMIT", "50"))
API_KEY = os.getenv("API_KEY")

# === HTTP Session for HuggingFace ===
def build_http_session() -> requests.Session:
    """Builds a requests session with retry logic."""
    session = requests.Session()
    retries = Retry(
        total=3, backoff_factor=0.5, status_forcelist=(429, 500, 502, 503, 504)
    )
    adapter = HTTPAdapter(max_retries=retries)
    session.mount("https://", adapter)
    session.mount("http://", adapter)
    return session

http = build_http_session()

# === Database Initialization ===
with app.app_context():
    init_db()

# === Authentication ===
def require_api_key(f):
    """Decorator to protect routes with an API key."""

    @wraps(f)
    def decorated_function(*args, **kwargs):
        if not API_KEY:
            logger.warning("API_KEY is not set. Authentication is disabled.")
            return f(*args, **kwargs)

        key = request.headers.get("X-API-KEY")
        if key != API_KEY:
            return jsonify({"status": "error", "message": "Invalid API key"}), 401
        return f(*args, **kwargs)

    return decorated_function

# === Helpers ===
def is_promotional(text: Optional[str]) -> bool:
    """Checks if an SMS is promotional based on keywords."""
    if not text:
        return True
    text_lower = text.lower()
    promo_keywords = [
        "insurance",
        "loan offer",
        "apply now",
        "limited period offer",
        "download app",
        "sale",
        "discount",
        "emi offer",
    ]
    txn_keywords = [
        "debited",
        "credited",
        "withdrawn",
        "payment",
        "transfer",
        "txn",
        "transaction",
        "purchase",
    ]
    if any(word in text_lower for word in txn_keywords):
        return False
    if any(word in text_lower for word in promo_keywords):
        return True
    return False


def parse_sms_with_regex(sms: str) -> Dict[str, Optional[str]]:
    """Parses an SMS using regex as a fallback."""
    if not sms:
        return {}
    data = {
        "amount": None,
        "txn_type": None,
        "mode": None,
        "ref_no": None,
        "account": None,
        "date": None,
        "balance": None,
        "vendor": None,
        "category": "Other",
    }
    amount_match = re.search(r"(?i)(?:INR|Rs\.?|₹)\s*([\d,]+\.?\d*)", sms)
    if amount_match:
        data["amount"] = amount_match.group(1).replace(",", "")
    ref_match = re.search(
        r"(?i)(?:Ref(?:erence)?(?:\s*No)?\.?)\s*[:\-]?\s*([A-Za-z0-9\-_/]+)", sms
    )
    if ref_match:
        data["ref_no"] = ref_match.group(1)
    account_match = re.search(r"(?i)(?:A/c(?:\s*XX)?\s*)(\d+)", sms)
    if account_match:
        data["account"] = account_match.group(1)
    date_match = re.search(
        r"(\d{1,2}[-/][A-Za-z]{3}[-/]\d{2,4}|\d{1,2}[-/]\d{1,2}[-/]\d{2,4})", sms
    )
    if date_match:
        data["date"] = date_match.group(1)
    balance_match = re.search(
        r"(?i)(?:Avl Bal|balance)[\s:]*[₹Rs\.]*\s*([\d,]+\.?\d*)", sms
    )
    if balance_match:
        data["balance"] = balance_match.group(1).replace(",", "")
    if re.search(r"(?i)\b(debited?|spent|withdrawn|deducted|purchas(?:e|ed))\b", sms):
        data["txn_type"] = "Debit"
    elif re.search(r"(?i)\b(credited?|received|deposited|refunded?)\b", sms):
        data["txn_type"] = "Credit"
    if re.search(r"(?i)\b(UPI|GPay|PhonePe|Paytm)\b", sms):
        data["mode"] = "UPI"
    elif re.search(r"(?i)\b(ATM|Cash)\b", sms):
        data["mode"] = "ATM"
    elif re.search(r"(?i)\b(NEFT|IMPS|RTGS|Net\s*Banking)\b", sms):
        data["mode"] = "NetBanking"
    return data


def extract_transaction_details_with_llm(sms_body: str) -> Dict[str, Any]:
    """Extracts transaction details from an SMS using an LLM."""
    if not HUGGINGFACE_API_KEY:
        logger.warning("HF_API_KEY not set. Falling back to regex.")
        return parse_sms_with_regex(sms_body)

    prompt = f"""[INST] You are an expert financial transaction parser. Analyze the following SMS message and extract the transaction details.
    Your response MUST be a single, valid JSON object and nothing else.
    The JSON object should have these keys: "amount", "txn_type" (must be "Credit" or "Debit"), "vendor" (the merchant name, e.g., "Zomato", "Amazon"), "category" (e.g., "Food", "Shopping", "Salary", "Travel"), "mode" (e.g., "UPI", "Card", "ATM", "NetBanking"), "date".
    If a value is not present, use null. Extract the amount as a number, without currency symbols.

    SMS: "{sms_body}"
    [/INST]"""

    headers = {"Authorization": f"Bearer {HUGGINGFACE_API_KEY}"}
    payload = {"inputs": prompt, "parameters": {"max_new_tokens": 256, "return_full_text": False}}

    try:
        resp = http.post(HF_API_URL, headers=headers, json=payload, timeout=20)
        resp.raise_for_status()
        response_text = resp.json()[0]["generated_text"]
        json_match = re.search(r"\{.*\}", response_text, re.DOTALL)
        if json_match:
            parsed_json = json.loads(json_match.group(0))
            logger.info(f"LLM successfully parsed: {parsed_json}")
            return parsed_json
        else:
            raise ValueError("No valid JSON object found in LLM response")
    except Exception as e:
        logger.error(f"LLM parsing failed: {e}. Falling back to regex.")
        return parse_sms_with_regex(sms_body)


def parse_sms(sms: str) -> Dict[str, Any]:
    """Parses an SMS by trying the LLM first and falling back to regex."""
    llm_result = extract_transaction_details_with_llm(sms)
    if not llm_result or not all(
        llm_result.get(k) for k in ["amount", "txn_type", "vendor", "category"]
    ):
        regex_result = parse_sms_with_regex(sms)
        return {**regex_result, **llm_result}
    return llm_result


def classify_text(text: str) -> str:
    """Classifies text into a category."""
    # Placeholder for a more sophisticated classification model
    return "Other"


def json_safe(val):
    """Converts Decimal and date/datetime objects to JSON serializable types."""
    if isinstance(val, Decimal):
        return float(val)
    if isinstance(val, (datetime, date)):
        return val.isoformat()
    return val


def clamp_limit(val):
    """Clamps a value to be within the allowed limit."""
    return max(1, min(int(val), MAX_LIMIT))


# === Blueprints ===
prediction_bp = Blueprint("prediction", __name__)
records_bp = Blueprint("records", __name__)
health_bp = Blueprint("health", __name__)
bills_bp = Blueprint("bills", __name__)
categories_bp = Blueprint("categories", __name__)
budgets_bp = Blueprint("budgets", __name__)


# === Prediction Route ===
@prediction_bp.route("/predictions/bulk", methods=["POST"])
@require_api_key
def predict_bulk():
    """Processes a bulk of SMS messages and saves them to the database."""
    data = request.get_json(silent=True) or {}
    errors = validate_payload(data, bulk_prediction_schema)
    if errors:
        return jsonify({"status": "error", "message": errors}), 400

    uid = data.get("uid")
    messages = data.get("messages", [])

    conn = get_db_connection()
    cur = conn.cursor()
    timestamp = datetime.utcnow()

    results = []
    insert_values = []
    for msg in messages:
        sms = msg.get("sms")
        sender = msg.get("sender")
        if not sms or is_promotional(sms):
            continue
        parsed = parse_sms(sms)
        amount = float(parsed["amount"]) if parsed.get("amount") else None
        balance = float(parsed["balance"]) if parsed.get("balance") else None
        txn_type = parsed.get("txn_type")
        category = classify_text(sms)
        insert_values.append(
            (
                uid,
                sms,
                category,
                amount,
                txn_type,
                parsed.get("mode"),
                parsed.get("ref_no"),
                parsed.get("account"),
                parsed.get("date"),
                balance,
                sender,
                timestamp,
            )
        )
        results.append(
            {
                "uid": uid,
                "sms": sms,
                "sender": sender,
                "category": category,
                "amount": amount,
                "txn_type": txn_type,
                "mode": parsed.get("mode"),
                "ref_no": parsed.get("ref_no"),
                "account": parsed.get("account"),
                "date": parsed.get("date"),
                "balance": balance,
                "created_at": timestamp.strftime("%Y-%m-%dT%H:%M:%SZ"),
            }
        )
    if insert_values:
        cur.executemany(
            """INSERT INTO sms_records (uid, sms, category, amount, txn_type, mode, ref_no, account, date, balance, sender, created_at) VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)""",
            insert_values,
        )
        conn.commit()
    
    cur.close()
    put_db_connection(conn)

    return jsonify({"status": "success", "count": len(results), "data": results}), 200


# === Records Route ===
@records_bp.route("/users/<uid>/records", methods=["GET"])
@require_api_key
def get_user_records(uid):
    """Fetches transaction records for a user."""
    limit = clamp_limit(request.args.get("limit", DEFAULT_LIMIT))
    offset = max(0, int(request.args.get("offset", 0)))

    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)

    query = """WITH user_records AS (
        SELECT * FROM sms_records WHERE uid = %s
    ),
    monthly_summary AS (
        SELECT
            COALESCE(SUM(CASE WHEN txn_type = 'Credit' THEN amount ELSE 0 END), 0) AS monthly_income,
            COALESCE(SUM(CASE WHEN txn_type = 'Debit' THEN amount ELSE 0 END), 0) AS monthly_expenses
        FROM user_records
        WHERE date_trunc('month', created_at) = date_trunc('month', CURRENT_DATE)
    )
    SELECT
        (SELECT COUNT(*) FROM user_records) AS total_count,
        (SELECT monthly_income FROM monthly_summary) AS monthly_income,
        (SELECT monthly_expenses FROM monthly_summary) AS monthly_expenses,
        id, uid, sms, category, amount, txn_type, mode, ref_no, account, date, balance, created_at
    FROM user_records
    ORDER BY created_at DESC
    LIMIT %s OFFSET %s;"""

    cur.execute(query, (uid, limit, offset))
    rows = cur.fetchall()

    cur.close()
    put_db_connection(conn)

    if not rows:
        return jsonify({"status": "success", "total": 0, "count": 0, "limit": limit, "offset": offset, "data": [], "summary": {"monthlyIncome": 0, "monthlyExpenses": 0}})

    total_count = rows[0]["total_count"]
    monthly_income = rows[0]["monthly_income"]
    monthly_expenses = rows[0]["monthly_expenses"]

    data = [{k: json_safe(v) for k, v in row.items() if k not in ["total_count", "monthly_income", "monthly_expenses"]} for row in rows]

    response = {
        "status": "success",
        "total": total_count,
        "count": len(data),
        "limit": limit,
        "offset": offset,
        "data": data,
        "summary": {
            "monthlyIncome": json_safe(monthly_income),
            "monthlyExpenses": json_safe(monthly_expenses),
        },
    }

    return jsonify(response), 200


# === Bills Routes ===
def predict_bill_category(text, sender):
    """Predicts the category of a bill based on its text and sender."""
    headers = {"Authorization": f"Bearer {HUGGINGFACE_API_KEY}"}
    payload = {
        "inputs": f"{text} From: {sender}",
        "parameters": {
            "candidate_labels": ["Electricity", "Water", "Internet", "Phone", "Other"]
        },
    }
    response = requests.post(HF_API_URL, headers=headers, json=payload)
    if response.status_code == 200:
        result = response.json()
        return result["labels"][0]
    return "Other"


@bills_bp.route("/bills/parse", methods=["POST"])
@require_api_key
def parse_bills_from_sms():
    """Parses bills from a list of SMS messages."""
    data = request.json
    errors = validate_payload(data, bill_parse_schema)
    if errors:
        return jsonify({"status": "error", "message": errors}), 400

    uid = data["uid"]
    messages = data["messages"]
    new_bills = []

    conn = get_db_connection()
    cur = conn.cursor()

    for msg in messages:
        body = msg.get("body", "")
        sender = msg.get("sender", "")
        match = re.search(
            r"(?P<amount>\d+\.?\d*)\s*(?:INR|₹)?(?:\s*is)?\s*(?:due|due date|due on)\s*(?P<date>\d{2}[-/]\d{2}[-/]\d{4})",
            body,
            re.IGNORECASE,
        )
        if match:
            category = predict_bill_category(body, sender)
            bill_id = str(uuid.uuid4())
            due_date_str = match.group("date").replace("/", "-")
            due_date = datetime.strptime(due_date_str, "%d-%m-%Y").date()
            amount = float(match.group("amount"))

            cur.execute(
                """INSERT INTO bills (id, user_id, name, category, due_date, amount, status, sms_sender, sms_body, created_at, updated_at)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, NOW(), NOW()) ON CONFLICT (id) DO NOTHING""",
                (
                    bill_id,
                    uid,
                    category,
                    category,
                    due_date,
                    amount,
                    "Unpaid",
                    sender,
                    body,
                ),
            )

            new_bills.append(
                {
                    "id": bill_id,
                    "user_id": uid,
                    "name": category,
                    "category": category,
                    "due_date": due_date.isoformat(),
                    "amount": amount,
                    "status": "Unpaid",
                }
            )

    conn.commit()
    
    cur.close()
    put_db_connection(conn)

    return jsonify({"parsed_bills": new_bills})


@bills_bp.route("/users/<uid>/bills", methods=["GET"])
@require_api_key
def get_bills(uid):
    """Fetches bills for a user, with optional status filtering."""
    filter_status = request.args.get("filter", "All")

    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)

    if filter_status == "All":
        cur.execute(
            "SELECT * FROM bills WHERE user_id = %s ORDER BY due_date ASC", (uid,)
        )
    else:
        cur.execute(
            "SELECT * FROM bills WHERE user_id = %s AND status = %s ORDER BY due_date ASC",
            (uid, filter_status),
        )

    bills = cur.fetchall()
    
    cur.close()
    put_db_connection(conn)

    return jsonify([dict(row) for row in bills])


# === Category Routes ===
@categories_bp.route("/users/<uid>/category-spending", methods=["GET"])
@require_api_key
def category_spending(uid):
    """Calculates spending per category for a user."""
    txn_type = request.args.get("type")
    period = request.args.get("period")
    sort = request.args.get("sort", "desc").lower()

    query = "SELECT category, SUM(amount) AS total_spent FROM sms_records WHERE uid = %s AND txn_type IN ('Credit', 'Debit')"
    params = [uid]

    if txn_type in ["Credit", "Debit"]:
        query += " AND txn_type = %s"
        params.append(txn_type)

    if period == "weekly":
        query += " AND created_at >= NOW() - INTERVAL '7 days'"
    elif period == "monthly":
        query += " AND created_at >= NOW() - INTERVAL '30 days'"

    query += " GROUP BY category"
    query += f" ORDER BY total_spent {('ASC' if sort == 'asc' else 'DESC')}"

    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    cur.execute(query, tuple(params))
    results = cur.fetchall()
    
    cur.close()
    put_db_connection(conn)

    return jsonify({"status": "success", "data": results})


# === Budgets Routes ===
@budgets_bp.route("/users/<uid>/budgets", methods=["GET"])
@require_api_key
def get_budgets(uid):
    """Fetches budgets for a user."""
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    cur.execute(
        "SELECT id, uid, name, cap, currency, period, created_at FROM budgets WHERE uid = %s",
        (uid,),
    )
    budgets = cur.fetchall()
    
    cur.close()
    put_db_connection(conn)

    return jsonify({"budgets": [dict(b) for b in budgets]})


@budgets_bp.route("/budgets", methods=["POST"])
@require_api_key
def create_budget():
    """Creates a new budget for a user."""
    data = request.json
    errors = validate_payload(data, budget_schema)
    if errors:
        return jsonify({"status": "error", "message": errors}), 400

    uid = data.get("uid")
    name = data.get("name")
    cap = data.get("cap")
    currency = data.get("currency", "INR")
    period = data.get("period")

    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute(
        "INSERT INTO budgets (uid, name, cap, currency, period) VALUES (%s, %s, %s, %s, %s) RETURNING id",
        (uid, name, cap, currency, period),
    )
    budget_id = cur.fetchone()[0]
    conn.commit()
    
    cur.close()
    put_db_connection(conn)

    return jsonify({"message": "Budget created", "id": budget_id}), 201


@budgets_bp.route("/budgets/<int:budget_id>", methods=["PUT"])
@require_api_key
def update_budget(budget_id):
    """Updates an existing budget."""
    data = request.json
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute(
        """UPDATE budgets
        SET name = COALESCE(%s, name), cap = COALESCE(%s, cap), currency = COALESCE(%s, currency), period = COALESCE(%s, period)
        WHERE id = %s""",
        (
            data.get("name"),
            data.get("cap"),
            data.get("currency"),
            data.get("period"),
            budget_id,
        ),
    )
    conn.commit()
    
    cur.close()
    put_db_connection(conn)

    return jsonify({"message": "Budget updated"}), 200


@budgets_bp.route("/budgets/<int:budget_id>", methods=["DELETE"])
@require_api_key
def delete_budget(budget_id):
    """Deletes a budget."""
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("DELETE FROM budgets WHERE id = %s", (budget_id,))
    conn.commit()
    
    cur.close()
    put_db_connection(conn)

    return jsonify({"message": "Budget deleted"}), 200


# === Health Route ===
@health_bp.route("/health", methods=["GET"])
def health_check():
    """Health check endpoint."""
    return jsonify({"status": "ok", "message": "✅ SpendSense Server is running!"})


# Register Blueprints
app.register_blueprint(prediction_bp, url_prefix="/api")
app.register_blueprint(records_bp, url_prefix="/api")
app.register_blueprint(health_bp, url_prefix="/api")
app.register_blueprint(bills_bp, url_prefix="/api")
app.register_blueprint(categories_bp, url_prefix="/api")
app.register_blueprint(budgets_bp, url_prefix="/api")


@app.after_request
def set_security_headers(resp):
    """Set security headers for all responses."""
    resp.headers["X-Content-Type-Options"] = "nosniff"
    resp.headers["X-Frame-Options"] = "DENY"
    resp.headers["X-XSS-Protection"] = "1; mode=block"
    return resp


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=False)
