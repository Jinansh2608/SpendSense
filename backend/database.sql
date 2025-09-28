-- Drop tables if they exist
DROP TABLE IF EXISTS sms_records;
DROP TABLE IF EXISTS bills;

-- SMS Records table
CREATE TABLE sms_records (
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
CREATE TABLE bills (
    id SERIAL PRIMARY KEY,
    uid VARCHAR(255) NOT NULL,              -- User identifier
    sender VARCHAR(255) NOT NULL,           -- SMS sender or biller name
    body TEXT NOT NULL,                     -- Original bill message text
    amount NUMERIC(10, 2) NOT NULL,         -- Bill amount
    due_date DATE NOT NULL,                 -- Due date of the bill
    category VARCHAR(100),                  -- Electricity, Water, Internet, etc.
    status VARCHAR(50) DEFAULT 'Unpaid',    -- Paid / Unpaid
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

 CREATE TABLE IF NOT EXISTS budgets (
            id SERIAL PRIMARY KEY,
            uid VARCHAR(255) NOT NULL,
            name VARCHAR(255) NOT NULL,
            cap NUMERIC(12, 2) NOT NULL,
            currency VARCHAR(10) DEFAULT 'INR',
            period VARCHAR(20) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
-- Indexes for performance
CREATE INDEX idx_uid_sms ON sms_records(uid);
CREATE INDEX idx_uid_bills ON bills(uid);
CREATE INDEX idx_category_sms ON sms_records(category);
CREATE INDEX idx_category_bills ON bills(category);
CREATE INDEX idx_status_bills ON bills(status);
