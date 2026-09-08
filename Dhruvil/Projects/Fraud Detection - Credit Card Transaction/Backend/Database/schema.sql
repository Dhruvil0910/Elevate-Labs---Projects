-- ================================================================
-- FRAUD DETECTION SYSTEM — FULL SCHEMA
-- Database: fraud_detection
-- ================================================================

-- ── 1. USERS ─────────────────────────────────────────────────────
-- Stores analysts/admins who log into the Flutter app

CREATE TABLE IF NOT EXISTS users (
    id            SERIAL PRIMARY KEY,
    username      VARCHAR(50)  UNIQUE NOT NULL,
    email         VARCHAR(100) UNIQUE NOT NULL,
    mobile        VARCHAR(30) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,          -- bcrypt hash, never plain text
    role          VARCHAR(20)  NOT NULL DEFAULT 'analyst'
                               CHECK (role IN ('admin', 'analyst', 'viewer')),
    is_active     BOOLEAN      NOT NULL DEFAULT TRUE,
    last_login    TIMESTAMP,
    created_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ── 2. TRANSACTIONS ──────────────────────────────────────────────
-- Raw input data — one row per transaction submitted for analysis
-- Mirrors the Kaggle creditcard.csv feature columns exactly

CREATE TABLE IF NOT EXISTS transactions (
    id            SERIAL PRIMARY KEY,
    submitted_by  INTEGER REFERENCES users(id) ON DELETE SET NULL,
    batch_job_id  INTEGER,                        -- FK added after batch_jobs table
    time_val      FLOAT        NOT NULL,          -- 'Time' (seconds since first txn)
    amount        FLOAT        NOT NULL,
    v1            FLOAT        NOT NULL DEFAULT 0,
    v2            FLOAT        NOT NULL DEFAULT 0,
    v3            FLOAT        NOT NULL DEFAULT 0,
    v4            FLOAT        NOT NULL DEFAULT 0,
    v5            FLOAT        NOT NULL DEFAULT 0,
    v6            FLOAT        NOT NULL DEFAULT 0,
    v7            FLOAT        NOT NULL DEFAULT 0,
    v8            FLOAT        NOT NULL DEFAULT 0,
    v9            FLOAT        NOT NULL DEFAULT 0,
    v10           FLOAT        NOT NULL DEFAULT 0,
    v11           FLOAT        NOT NULL DEFAULT 0,
    v12           FLOAT        NOT NULL DEFAULT 0,
    v13           FLOAT        NOT NULL DEFAULT 0,
    v14           FLOAT        NOT NULL DEFAULT 0,
    v15           FLOAT        NOT NULL DEFAULT 0,
    v16           FLOAT        NOT NULL DEFAULT 0,
    v17           FLOAT        NOT NULL DEFAULT 0,
    v18           FLOAT        NOT NULL DEFAULT 0,
    v19           FLOAT        NOT NULL DEFAULT 0,
    v20           FLOAT        NOT NULL DEFAULT 0,
    v21           FLOAT        NOT NULL DEFAULT 0,
    v22           FLOAT        NOT NULL DEFAULT 0,
    v23           FLOAT        NOT NULL DEFAULT 0,
    v24           FLOAT        NOT NULL DEFAULT 0,
    v25           FLOAT        NOT NULL DEFAULT 0,
    v26           FLOAT        NOT NULL DEFAULT 0,
    v27           FLOAT        NOT NULL DEFAULT 0,
    v28           FLOAT        NOT NULL DEFAULT 0,
    source        VARCHAR(20)  NOT NULL DEFAULT 'manual'
                               CHECK (source IN ('manual', 'batch', 'api')),
    created_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ── 3. PREDICTIONS ───────────────────────────────────────────────
-- ML model output — one row per transaction (1:1 with transactions)

CREATE TABLE IF NOT EXISTS predictions (
    id                SERIAL PRIMARY KEY,
    transaction_id    INTEGER UNIQUE NOT NULL
                      REFERENCES transactions(id) ON DELETE CASCADE,
    -- Final ensemble result
    prediction        VARCHAR(20)  NOT NULL CHECK (prediction IN ('FRAUD', 'LEGITIMATE')),
    is_fraud          BOOLEAN      NOT NULL,
    fraud_score       FLOAT        NOT NULL CHECK (fraud_score BETWEEN 0 AND 1),
    votes             INTEGER      NOT NULL CHECK (votes BETWEEN 0 AND 3),
    -- Individual model results
    iso_result        VARCHAR(20)  CHECK (iso_result IN ('FRAUD', 'LEGITIMATE')),
    lof_result        VARCHAR(20)  CHECK (lof_result IN ('FRAUD', 'LEGITIMATE')),
    xgb_result        VARCHAR(20)  CHECK (xgb_result IN ('FRAUD', 'LEGITIMATE')),
    xgb_probability   FLOAT        CHECK (xgb_probability BETWEEN 0 AND 1),
    -- Analyst review (optional manual override)
    reviewed_by       INTEGER REFERENCES users(id) ON DELETE SET NULL,
    review_status     VARCHAR(20)  DEFAULT 'pending'
                                   CHECK (review_status IN ('pending', 'confirmed', 'disputed')),
    review_note       TEXT,
    reviewed_at       TIMESTAMP,
    created_at        TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ── 4. BATCH JOBS ────────────────────────────────────────────────
-- Tracks every CSV upload — progress, status, summary

CREATE TABLE IF NOT EXISTS batch_jobs (
    id              SERIAL PRIMARY KEY,
    submitted_by    INTEGER REFERENCES users(id) ON DELETE SET NULL,
    filename        VARCHAR(255) NOT NULL,
    file_size_bytes INTEGER,
    total_rows      INTEGER,
    processed_rows  INTEGER      DEFAULT 0,
    fraud_count     INTEGER      DEFAULT 0,
    legit_count     INTEGER      DEFAULT 0,
    status          VARCHAR(20)  NOT NULL DEFAULT 'pending'
                                 CHECK (status IN ('pending','processing','completed','failed')),
    error_message   TEXT,
    started_at      TIMESTAMP,
    completed_at    TIMESTAMP,
    created_at      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Now add the FK from transactions → batch_jobs
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'fk_transactions_batch_job'
    ) THEN
        ALTER TABLE transactions
            ADD CONSTRAINT fk_transactions_batch_job
            FOREIGN KEY (batch_job_id) REFERENCES batch_jobs(id) ON DELETE SET NULL;
    END IF;
END $$;

-- ── 5. MODEL METRICS ─────────────────────────────────────────────
-- Saves training run results so you can track model improvement over time

CREATE TABLE IF NOT EXISTS model_metrics (
    id                  SERIAL PRIMARY KEY,
    model_version       VARCHAR(50)  NOT NULL,     -- e.g. 'v1.0', 'v1.1'
    model_type          VARCHAR(50)  NOT NULL,     -- 'xgboost', 'isolation_forest', 'ensemble'
    auc_score           FLOAT,
    accuracy            FLOAT,
    precision_fraud     FLOAT,
    recall_fraud        FLOAT,
    f1_fraud            FLOAT,
    confusion_matrix    JSONB,                     -- [[TN,FP],[FN,TP]]
    training_rows       INTEGER,
    test_rows           INTEGER,
    is_active           BOOLEAN      DEFAULT FALSE, -- which version is currently loaded
    trained_at          TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ── 6. AUDIT LOG ─────────────────────────────────────────────────
-- Immutable record of every important action — required for fraud systems

CREATE TABLE IF NOT EXISTS audit_log (
    id          SERIAL PRIMARY KEY,
    user_id     INTEGER REFERENCES users(id) ON DELETE SET NULL,
    action      VARCHAR(50)  NOT NULL,  -- 'predict', 'batch_upload', 'review', 'login'
    entity      VARCHAR(50),            -- 'transaction', 'batch_job', 'prediction'
    entity_id   INTEGER,               -- ID of the affected row
    detail      JSONB,                 -- any extra context as JSON
    ip_address  VARCHAR(45),           -- supports IPv6
    created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ================================================================
-- INDEXES — for query performance
-- ================================================================

-- Predictions — most common query is fetching fraud cases, sorted by time
CREATE INDEX IF NOT EXISTS idx_predictions_is_fraud
    ON predictions (is_fraud);
CREATE INDEX IF NOT EXISTS idx_predictions_created_at
    ON predictions (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_predictions_fraud_score
    ON predictions (fraud_score DESC);

-- Transactions — filter by user or batch
CREATE INDEX IF NOT EXISTS idx_transactions_submitted_by
    ON transactions (submitted_by);
CREATE INDEX IF NOT EXISTS idx_transactions_batch_job_id
    ON transactions (batch_job_id);
CREATE INDEX IF NOT EXISTS idx_transactions_created_at
    ON transactions (created_at DESC);

-- Batch jobs — filter by status
CREATE INDEX IF NOT EXISTS idx_batch_jobs_status
    ON batch_jobs (status);
CREATE INDEX IF NOT EXISTS idx_batch_jobs_submitted_by
    ON batch_jobs (submitted_by);

-- Audit log — filter by user or action type
CREATE INDEX IF NOT EXISTS idx_audit_log_user_id
    ON audit_log (user_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_action
    ON audit_log (action);
CREATE INDEX IF NOT EXISTS idx_audit_log_created_at
    ON audit_log (created_at DESC);

-- ================================================================
-- DEFAULT ADMIN USER (change password immediately after setup)
-- password_hash below = bcrypt of 'Admin@1234'
-- ================================================================

INSERT INTO users (username, email, password_hash, role)
VALUES (
    'admin',
    'admin@frauddetect.com',
    '$2b$12$KIX8/TNEkHq3cDuF.5nHxOv3b2Tl6I3z4f5gP9nqR2sL7mY1oWkCe',
    'admin'
) ON CONFLICT DO NOTHING;