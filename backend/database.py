import os
import psycopg2
from psycopg2.pool import SimpleConnectionPool
from psycopg2.extras import RealDictCursor
import logging

logger = logging.getLogger("spendsense.database")

POOL_MIN = int(os.getenv("DB_POOL_MIN", "1"))
POOL_MAX = int(os.getenv("DB_POOL_MAX", "10"))

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

_db_pool: SimpleConnectionPool | None = None

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

def init_db():
    conn = None
    cur = None
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        # Updated sms_records table with a 'vendor' column
        cur.execute("""
            CREATE TABLE IF NOT EXISTS sms_records (
                id SERIAL PRIMARY KEY,
                uid TEXT NOT NULL,
                sms TEXT NOT NULL,
                category TEXT,
                amount NUMERIC,
                txn_type TEXT,
                mode TEXT,
                ref_no TEXT,
                account TEXT,
                date TEXT,
                balance NUMERIC,
                sender TEXT,
                vendor TEXT, 
                created_at TIMESTAMP DEFAULT NOW()
            );
        """)
        cur.execute("""
            CREATE TABLE IF NOT EXISTS bills (
                id TEXT PRIMARY KEY,
                user_id TEXT NOT NULL,
                name TEXT NOT NULL,
                category TEXT NOT NULL,
                due_date DATE NOT NULL,
                amount NUMERIC NOT NULL,
                status TEXT NOT NULL,
                sms_sender TEXT,
                sms_body TEXT,
                created_at TIMESTAMP DEFAULT NOW(),
                updated_at TIMESTAMP DEFAULT NOW()
            );
        """)
        cur.execute("""
            CREATE TABLE IF NOT EXISTS budgets (
                id SERIAL PRIMARY KEY,
                uid TEXT NOT NULL,
                name TEXT NOT NULL,
                cap NUMERIC NOT NULL,
                currency TEXT NOT NULL,
                period TEXT NOT NULL,
                created_at TIMESTAMP DEFAULT NOW()
            );
        """)
        conn.commit()
        logger.info("✅ Database initialized successfully.")
    except Exception as e:
        logger.error(f"❌ DB Init Failed: {e}")
        if conn: conn.rollback()
    finally:
        if cur: cur.close()
        if conn: put_db_connection(conn)