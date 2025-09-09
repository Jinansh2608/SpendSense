import os
from flask import Blueprint, request, jsonify, current_app
from psycopg2 import pool
from dotenv import load_dotenv

load_dotenv()

DB_CONFIG = {
    "dbname": os.getenv("DB_NAME"),
    "user": os.getenv("DB_USER"),
    "password": os.getenv("DB_PASSWORD"),
    "host": os.getenv("DB_HOST"),
    "port": os.getenv("DB_PORT")
}

# Connection pool
connection_pool = pool.SimpleConnectionPool(1, 10, **DB_CONFIG)

def get_connection():
    return connection_pool.getconn()

def release_connection(conn):
    connection_pool.putconn(conn)

budgets_bp = Blueprint("budgets", __name__)

# Initialize budgets table
def init_budgets_table():
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        CREATE TABLE IF NOT EXISTS budgets (
            id SERIAL PRIMARY KEY,
            uid VARCHAR(255) NOT NULL,
            name VARCHAR(255) NOT NULL,
            cap NUMERIC(12, 2) NOT NULL,
            currency VARCHAR(10) DEFAULT 'INR',
            period VARCHAR(20) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)
    conn.commit()
    cur.close()
    release_connection(conn)

# --- Routes ---
@budgets_bp.route("/budgets/<uid>", methods=["GET"])
def get_budgets(uid):
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("SELECT id, uid, name, cap, currency, period, created_at FROM budgets WHERE uid = %s", (uid,))
    rows = cur.fetchall()
    cur.close()
    release_connection(conn)

    budgets = [
        {
            "id": row[0],
            "uid": row[1],
            "name": row[2],
            "cap": float(row[3]),
            "currency": row[4],
            "period": row[5],
            "created_at": row[6].isoformat()
        }
        for row in rows
    ]
    return jsonify({"budgets": budgets})


@budgets_bp.route("/budgets", methods=["POST"])
def create_budget():
    data = request.json
    uid = data.get("uid")
    name = data.get("name")
    cap = data.get("cap")
    currency = data.get("currency", "INR")
    period = data.get("period")

    if not uid or not name or not cap or not period:
        return jsonify({"error": "Missing required fields"}), 400

    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        INSERT INTO budgets (uid, name, cap, currency, period)
        VALUES (%s, %s, %s, %s, %s) RETURNING id
    """, (uid, name, cap, currency, period))
    budget_id = cur.fetchone()[0]
    conn.commit()
    cur.close()
    release_connection(conn)

    return jsonify({"message": "Budget created", "id": budget_id}), 201


@budgets_bp.route("/budgets/<int:budget_id>", methods=["PUT"])
def update_budget(budget_id):
    data = request.json
    name = data.get("name")
    cap = data.get("cap")
    currency = data.get("currency")
    period = data.get("period")

    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        UPDATE budgets
        SET name = COALESCE(%s, name),
            cap = COALESCE(%s, cap),
            currency = COALESCE(%s, currency),
            period = COALESCE(%s, period)
        WHERE id = %s
    """, (name, cap, currency, period, budget_id))
    conn.commit()
    cur.close()
    release_connection(conn)

    return jsonify({"message": "Budget updated"}), 200


@budgets_bp.route("/budgets/<int:budget_id>", methods=["DELETE"])
def delete_budget(budget_id):
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("DELETE FROM budgets WHERE id = %s", (budget_id,))
    conn.commit()
    cur.close()
    release_connection(conn)

    return jsonify({"message": "Budget deleted"}), 200
