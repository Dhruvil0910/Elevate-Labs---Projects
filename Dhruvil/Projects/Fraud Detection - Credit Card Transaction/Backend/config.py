import os
from pathlib import Path
from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent
load_dotenv(BASE_DIR / 'load.env')

class Config:
    # Database
    DB_HOST     = os.getenv('DB_HOST',     'localhost')
    DB_PORT     = int(os.getenv('DB_PORT', '5432'))
    DB_NAME     = os.getenv('DB_NAME',     'fraud_detection')
    DB_USER     = os.getenv('DB_USER',     'fraud_user')
    DB_PASSWORD = os.getenv('DB_PASSWORD', 'psql1234')

    # Pool
    DB_MIN_CONN = int(os.getenv('DB_MIN_CONNECTIONS', '2'))
    DB_MAX_CONN = int(os.getenv('DB_MAX_CONNECTIONS', '10'))

    # Flask
    FLASK_PORT  = int(os.getenv('FLASK_PORT', '5000'))
    DEBUG       = os.getenv('FLASK_ENV') == 'development'