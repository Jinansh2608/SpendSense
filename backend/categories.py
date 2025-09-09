from flask import Blueprint, jsonify, request
import psycopg2
from psycopg2.extras import RealDictCursor
import logging
import os

# Logger
logger = logging.getLogger(__name__)

# Blueprint
categories_bp = Blueprint('categories', __name__)

# DB Config
DB_CONFIG = {
    "dbname": os.getenv("DB_NAME"),
    "user": os.getenv("DB_USER"),
    "password": os.getenv("DB_PASSWORD"),
    "host": os.getenv("DB_HOST"),
    "port": os.getenv("DB_PORT"),
}

# DB Connection
def get_db_connection():
    return psycopg2.connect(**DB_CONFIG, cursor_factory=RealDictCursor)

# === API Endpoint: Category-wise Spending ===
@categories_bp.route('/category-spending', methods=['GET'])
def category_spending():
    uid = request.args.get('uid')
    txn_type = request.args.get('type')  # credit or debit
    period = request.args.get('period')  # weekly or monthly
    sort = request.args.get('sort', 'desc').lower()  # asc or desc

    if not uid:
        return jsonify({"error": "UID is required"}), 400

    # === Build Dynamic Query ===
    query = """
        SELECT category, SUM(amount) AS total_spent
        FROM sms_records
        WHERE uid = %s AND txn_type IN ('credit', 'debit')
    """
    params = [uid]

    if txn_type in ['credit', 'debit']:
        query += " AND txn_type = %s"
        params.append(txn_type)

    if period == 'weekly':
        query += " AND date >= NOW() - INTERVAL '7 days'"
    elif period == 'monthly':
        query += " AND date >= NOW() - INTERVAL '30 days'"

    query += " GROUP BY category"

    if sort in ['asc', 'desc']:
        query += f" ORDER BY total_spent {sort.upper()}"
    else:
        query += " ORDER BY total_spent DESC"

    logger.info(f"Executing query: {query} with params {params}")

    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute(query, tuple(params))
        results = cur.fetchall()
        cur.close()
        conn.close()

        return jsonify({"status": "success", "data": results}), 200
    except Exception as e:
        logger.error(f"Error fetching category spending: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500
