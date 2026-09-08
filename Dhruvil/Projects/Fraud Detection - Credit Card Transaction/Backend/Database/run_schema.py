import os
from pathlib import Path

import psycopg2
from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent.parent
load_dotenv(BASE_DIR / 'load.env')

conn = psycopg2.connect(
    host=os.getenv('DB_HOST', 'localhost'),
    port=os.getenv('DB_PORT', '5432'),
    dbname=os.getenv('DB_NAME', 'fraud_detection'),
    user=os.getenv('DB_USER', 'fraud_user'),
    password=os.getenv('DB_PASSWORD', 'psql1234')
)
conn.autocommit = True

schema_path = os.path.join(os.path.dirname(__file__), 'schema.sql')

with conn.cursor() as cur:
    with open(schema_path, 'r', encoding='utf-8') as f:
        sql = f.read()
    cur.execute(sql)
    print('✓ Schema applied successfully.')

conn.close()