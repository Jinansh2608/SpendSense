-- Use CREATE TABLE IF NOT EXISTS to prevent errors if tables already exist.

-- SMS Records table
CREATE TABLE IF NOT EXISTS sms_records (
    id SERIAL PRIMARY KEY,
    uid VARCHAR(255) NOT NULL,              -- User identifier
    sms TEXT NOT NULL,                      -- Full SMS text
    category VARCHAR(100),                  -- e.g., Bill, Transaction, Promo
    amount NUMERIC(10, 2),                  -- Extracted amount
    txn_type VARCHAR(50),                   -- Credit / Debit
    mode VARCHAR(100),                      -- UPI, ATM, NetBanking
    ref_no VARCHAR(100),                    -- Transaction reference number
    account VARCHAR(100),                   -- Account number or identifier
    date TIMESTAMP,                         -- Transaction date
    balance NUMERIC(15, 2),                 -- Remaining balance
    sender VARCHAR(255) NOT NULL,           -- SMS sender (bank, service)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Bills table
CREATE TABLE IF NOT EXISTS bills (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    name VARCHAR(255),
    category VARCHAR(100),
    due_date DATE NOT NULL,
    amount NUMERIC(10, 2) NOT NULL,
    status VARCHAR(50) DEFAULT 'Unpaid',
    sms_sender VARCHAR(255),
    sms_body TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP
);

-- Budgets table
CREATE TABLE IF NOT EXISTS budgets (
    id SERIAL PRIMARY KEY,
    uid VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    cap NUMERIC(12, 2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'INR',
    period VARCHAR(20) NOT NULL, -- e.g., 'weekly', 'monthly', 'yearly'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Wallets table
CREATE TABLE IF NOT EXISTS wallets (
    id SERIAL PRIMARY KEY,
    uid VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    balance NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    currency VARCHAR(10) DEFAULT 'INR',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance
-- Note: CREATE INDEX IF NOT EXISTS is available in PostgreSQL 9.5+
-- If using an older version, you might need to handle this differently.
DO $
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_class c WHERE c.relname = 'idx_uid_sms' AND c.relkind = 'i') THEN
        CREATE INDEX idx_uid_sms ON sms_records(uid);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_class c WHERE c.relname = 'idx_uid_bills' AND c.relkind = 'i') THEN
        CREATE INDEX idx_uid_bills ON bills(user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_class c WHERE c.relname = 'idx_category_sms' AND c.relkind = 'i') THEN
        CREATE INDEX idx_category_sms ON sms_records(category);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_class c WHERE c.relname = 'idx_category_bills' AND c.relkind = 'i') THEN
        CREATE INDEX idx_category_bills ON bills(category);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_class c WHERE c.relname = 'idx_status_bills' AND c.relkind = 'i') THEN
        CREATE INDEX idx_status_bills ON bills(status);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_class c WHERE c.relname = 'idx_uid_budgets' AND c.relkind = 'i') THEN
        CREATE INDEX idx_uid_budgets ON budgets(uid);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_class c WHERE c.relname = 'idx_uid_wallets' AND c.relkind = 'i') THEN
        CREATE INDEX idx_uid_wallets ON wallets(uid);
    END IF;
END
$;

-- Alter table commands (examples)
-- These are commented out by default. Uncomment and modify as needed.

-- ALTER TABLE sms_records ADD COLUMN IF NOT EXISTS new_column_name a_data_type;
-- ALTER TABLE bills ADD COLUMN IF NOT EXISTS another_new_column a_data_type;
