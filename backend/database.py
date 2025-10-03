import os
import psycopg2
from psycopg2.pool import SimpleConnectionPool
from psycopg2.extras import RealDictCursor
import logging
from dotenv import load_dotenv

load_dotenv()

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
        with open('database.sql', 'r') as f:
            cur.execute(f.read())
        conn.commit()
        logger.info("✅ Database initialized successfully from database.sql.")
    except Exception as e:
        logger.error(f"❌ DB Init Failed: {e}")
        if conn: conn.rollback()
    finally:
        if cur: cur.close()
        if conn: put_db_connection(conn)