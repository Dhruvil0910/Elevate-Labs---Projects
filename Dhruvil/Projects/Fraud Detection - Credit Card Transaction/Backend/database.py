"""Compatibility wrapper for the database package.

The project currently imports DatabasePool and PredictionRepository from the
root-level module name `database`, but the actual implementation lives in the
`Database` package. Re-exporting from here preserves both import styles.
"""

from Database import DatabasePool, PredictionRepository

__all__ = ['DatabasePool', 'PredictionRepository']

# Backward-compatible helpers kept for older code paths that still call
# the legacy functions below.
import os
import psycopg2
from psycopg2.extras import RealDictCursor

DB_CONFIG = {
    'host':     os.getenv('DB_HOST',     'localhost'),
    'port':     os.getenv('DB_PORT',     '5432'),
    'dbname':   os.getenv('DB_NAME',     'fraud_detection'),
    'user':     os.getenv('DB_USER',     'postgres'),
    'password': os.getenv('DB_PASSWORD', 'yourpassword'),
}


def get_db():
    conn = psycopg2.connect(**DB_CONFIG, cursor_factory=RealDictCursor)
    return conn


def init_db():
    with get_db() as conn:
        with conn.cursor() as cur:
            cur.execute('''
                CREATE TABLE IF NOT EXISTS predictions (
                    id          SERIAL PRIMARY KEY,
                    amount      FLOAT,
                    prediction  VARCHAR(20),
                    fraud_score FLOAT,
                    votes       INTEGER,
                    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );
            ''')
        conn.commit()