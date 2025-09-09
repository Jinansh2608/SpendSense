import os
import re
import uuid
import requests
from datetime import datetime
from flask import Blueprint, request, jsonify
from dotenv import load_dotenv
import psycopg2
from psycopg2.extras import RealDictCursor

# Load environment variables
load_dotenv()

# Database config
DB_CONFIG = {
    "dbname": os.getenv("DB_NAME"),
    "user": os.getenv("DB_USER"),
    "password": os.getenv("DB_PASSWORD"),
    "host": os.getenv("DB_HOST"),
    "port": os.getenv("DB_PORT"),
}

# Hugging Face config
HF_API_KEY = os.getenv('HF_API_KEY')
HF_MODEL = os.getenv('HF_MODEL', 'facebook/bart-large-mnli')
HF_API_URL = f"https://api-inference.huggingface.co/models/{HF_MODEL}"

# Create Blueprint
bills_bp = Blueprint('bills', __name__)

# Database connection
def get_db_connection():
    conn = psycopg2.connect(**DB_CONFIG, cursor_factory=RealDictCursor)
    return conn

# Hugging Face zero-shot category prediction
def predict_category(text, sender):
    headers = {"Authorization": f"Bearer {HF_API_KEY}"}
    payload = {
        "inputs": f"{text} From: {sender}",
        "parameters": {
            "candidate_labels": ["Electricity", "Water", "Internet", "Phone", "Other"]
        }
    }
    response = requests.post(HF_API_URL, headers=headers, json=payload)
    if response.status_code == 200:
        result = response.json()
        return result['labels'][0]
    return "Other"

# ✅ Route: Parse SMS and save bills
@bills_bp.route('/bills/parse_sms', methods=['POST'])
def parse_sms():
    data = request.json
    uid = data['uid']
    messages = data['messages']
    new_bills = []

    conn = get_db_connection()
    cur = conn.cursor()

    for msg in messages:
        body = msg.get('body', '')
        sender = msg.get('sender', '')

        # Regex for amount and date
        match = re.search(
            r'(?P<amount>\d+\.?\d*)\s*(?:INR|₹)?(?:\s*is)?\s*(?:due|due date|due on)\s*(?P<date>\d{2}[-/]\d{2}[-/]\d{4})',
            body,
            re.IGNORECASE
        )
        if match:
            category = predict_category(body, sender)
            bill_id = str(uuid.uuid4())
            due_date_str = match.group('date').replace('/', '-')  # normalize date
            due_date = datetime.strptime(due_date_str, '%d-%m-%Y').date()
            amount = float(match.group('amount'))

            cur.execute("""
                INSERT INTO bills (id, user_id, name, category, due_date, amount, status, sms_sender, sms_body, created_at, updated_at)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, NOW(), NOW())
                ON CONFLICT (id) DO NOTHING
            """, (bill_id, uid, category, category, due_date, amount, 'Unpaid', sender, body))

            new_bills.append({
                'id': bill_id,
                'user_id': uid,
                'name': category,
                'category': category,
                'due_date': due_date.isoformat(),
                'amount': amount,
                'status': 'Unpaid',
                'sms_sender': sender,
                'sms_body': body,
            })

    conn.commit()
    cur.close()
    conn.close()

    return jsonify({'parsed_bills': new_bills})

# ✅ Route: Get bills for a user
@bills_bp.route('/bills', methods=['GET'])
def get_bills():
    uid = request.args.get('uid')
    filter_status = request.args.get('filter', 'All')

    conn = get_db_connection()
    cur = conn.cursor()

    if filter_status == 'All':
        cur.execute("SELECT * FROM bills WHERE user_id = %s ORDER BY due_date ASC", (uid,))
    else:
        cur.execute("SELECT * FROM bills WHERE user_id = %s AND status = %s ORDER BY due_date ASC", (uid, filter_status))

    bills = cur.fetchall()
    cur.close()
    conn.close()

    return jsonify(bills)
