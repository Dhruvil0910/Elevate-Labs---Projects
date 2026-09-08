-- ================================================================
-- FRAUD DETECTION SYSTEM — SAMPLE DATA SEED
-- Realistic transactions and predictions for testing
-- ================================================================

-- Ensure we have analyst and viewer users
INSERT INTO users (username, email, password_hash, role, is_active)
VALUES 
    ('analyst1', 'analyst1@frauddetect.com', '$2b$12$oYWEH9AxM1lIh6jLU1fnYOmQKX8ZZQM5KQ6X3n7vY2Z4wX9aB1KXG', 'analyst', TRUE),
    ('analyst2', 'analyst2@frauddetect.com', '$2b$12$oYWEH9AxM1lIh6jLU1fnYOmQKX8ZZQM5KQ6X3n7vY2Z4wX9aB1KXG', 'analyst', TRUE),
    ('viewer1', 'viewer1@frauddetect.com', '$2b$12$oYWEH9AxM1lIh6jLU1fnYOmQKX8ZZQM5KQ6X3n7vY2Z4wX9aB1KXG', 'viewer', TRUE)
ON CONFLICT (email) DO NOTHING;

-- Get user IDs for the seed data
-- We'll use a CTE to get the IDs and then insert transactions
INSERT INTO transactions (submitted_by, time_val, amount, source, created_at)
WITH user_data AS (
    SELECT (SELECT id FROM users WHERE email = 'analyst1@frauddetect.com') as uid1,
           (SELECT id FROM users WHERE email = 'analyst2@frauddetect.com') as uid2
)
SELECT uid1, 100, 45.99, 'api', NOW() - INTERVAL '5 days' FROM user_data
UNION ALL SELECT uid1, 150, 125.50, 'manual', NOW() - INTERVAL '5 days' FROM user_data
UNION ALL SELECT uid1, 200, 89.00, 'batch', NOW() - INTERVAL '4 days' FROM user_data
UNION ALL SELECT uid1, 250, 1250.00, 'api', NOW() - INTERVAL '4 days' FROM user_data
UNION ALL SELECT uid1, 300, 34.50, 'manual', NOW() - INTERVAL '3 days' FROM user_data
UNION ALL SELECT uid1, 350, 567.89, 'api', NOW() - INTERVAL '3 days' FROM user_data
UNION ALL SELECT uid1, 400, 92.33, 'batch', NOW() - INTERVAL '2 days' FROM user_data
UNION ALL SELECT uid1, 450, 2100.00, 'manual', NOW() - INTERVAL '2 days' FROM user_data
UNION ALL SELECT uid2, 500, 75.25, 'api', NOW() - INTERVAL '2 days' FROM user_data
UNION ALL SELECT uid2, 550, 234.56, 'batch', NOW() - INTERVAL '1 day' FROM user_data
UNION ALL SELECT uid2, 600, 450.00, 'manual', NOW() - INTERVAL '1 day' FROM user_data
UNION ALL SELECT uid2, 650, 78.99, 'api', NOW() - INTERVAL '1 day' FROM user_data
UNION ALL SELECT uid2, 700, 890.12, 'batch', NOW() - INTERVAL '12 hours' FROM user_data
UNION ALL SELECT uid2, 750, 156.34, 'api', NOW() - INTERVAL '6 hours' FROM user_data
UNION ALL SELECT uid1, 800, 3450.00, 'manual', NOW() - INTERVAL '3 hours' FROM user_data
ON CONFLICT DO NOTHING;

-- Insert fraud predictions
INSERT INTO predictions (transaction_id, prediction, is_fraud, fraud_score, votes, iso_result, lof_result, xgb_result, xgb_probability, review_status, created_at)
SELECT 
    id,
    CASE WHEN amount > 1000 THEN 'FRAUD' ELSE 'LEGITIMATE' END,
    CASE WHEN amount > 1000 THEN TRUE ELSE FALSE END,
    CASE WHEN amount > 1000 THEN 0.87 WHEN amount > 400 THEN 0.38 ELSE 0.12 END,
    CASE WHEN amount > 1000 THEN 3 WHEN amount > 400 THEN 2 ELSE 1 END,
    CASE WHEN amount > 1000 THEN 'FRAUD' ELSE 'LEGITIMATE' END,
    CASE WHEN amount > 800 THEN 'FRAUD' ELSE 'LEGITIMATE' END,
    CASE WHEN amount > 1200 THEN 'FRAUD' ELSE 'LEGITIMATE' END,
    CASE WHEN amount > 1000 THEN 0.89 ELSE 0.18 END,
    'pending',
    created_at
FROM transactions
WHERE created_at > NOW() - INTERVAL '6 days'
ON CONFLICT (transaction_id) DO NOTHING;

-- Insert audit log entries
INSERT INTO audit_log (user_id, action, entity, entity_id, detail, created_at)
WITH user_data AS (
    SELECT (SELECT id FROM users WHERE email = 'analyst1@frauddetect.com') as uid1,
           (SELECT id FROM users WHERE email = 'analyst2@frauddetect.com') as uid2
)
SELECT uid1, 'predict', 'transaction', NULL::INTEGER, '{"status":"completed"}'::JSONB, NOW() - INTERVAL '5 days' FROM user_data
UNION ALL SELECT uid2, 'predict', 'transaction', NULL::INTEGER, '{"status":"completed"}'::JSONB, NOW() - INTERVAL '3 days' FROM user_data
UNION ALL SELECT uid1, 'batch_upload', 'batch_job', NULL::INTEGER, '{"file":"transactions.csv"}'::JSONB, NOW() - INTERVAL '2 days' FROM user_data
UNION ALL SELECT uid2, 'review', 'prediction', NULL::INTEGER, '{"note":"verified"}'::JSONB, NOW() - INTERVAL '1 day' FROM user_data
ON CONFLICT DO NOTHING;
