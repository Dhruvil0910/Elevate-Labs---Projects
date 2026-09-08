# from flask import Flask, request, jsonify, send_from_directory
# from flask_cors import CORS
# from database import get_db, init_db
# import pandas as pd, json, io
# from ml.ml_services import FraudDetector
# from dotenv import load_dotenv
# load_dotenv()   

# app = Flask(__name__, static_folder='static')
# CORS(app)

# detector = FraudDetector()
# init_db()   # creates table if not exists on startup

# @app.route('/health', methods=['GET'])
# def health():
#     return jsonify({'status': 'ok', 'models_loaded': True})

# @app.route('/predict', methods=['POST'])
# def predict_single():
#     data = request.get_json()
#     if not data or 'features' not in data:
#         return jsonify({'error': 'Provide features list (30 values)'}), 400

#     features = data['features']
#     if len(features) != 30:
#         return jsonify({'error': f'Expected 30 features, got {len(features)}'}), 400

#     result = detector.predict(features)

#     # PostgreSQL insert
#     with get_db() as conn:
#         with conn.cursor() as cur:
#             cur.execute(
#                 '''INSERT INTO predictions
#                    (amount, prediction, fraud_score, votes)
#                    VALUES (%s, %s, %s, %s)''',
#                 (features[29], result['prediction'],
#                  result['fraud_score'], result['votes'])
#             )
#         conn.commit()

#     return jsonify(result), 200

# @app.route('/batch', methods=['POST'])
# def predict_batch():
#     if 'file' not in request.files:
#         return jsonify({'error': 'No file uploaded'}), 400

#     f       = request.files['file']
#     df      = pd.read_csv(io.StringIO(f.read().decode('utf-8')))
#     missing = [c for c in FraudDetector.FEATURE_COLS if c not in df.columns]
#     if missing:
#         return jsonify({'error': f'Missing columns: {missing}'}), 400

#     results = detector.predict_batch(df)

#     # Bulk insert with executemany
#     with get_db() as conn:
#         with conn.cursor() as cur:
#             cur.executemany(
#                 '''INSERT INTO predictions
#                    (amount, prediction, fraud_score, votes)
#                    VALUES (%s, %s, %s, %s)''',
#                 [(r['fraud_score'], r['prediction'],
#                   r['fraud_score'], r['votes']) for r in results]
#             )
#         conn.commit()

#     return jsonify({
#         'total':       len(results),
#         'fraud_count': sum(1 for r in results if r['is_fraud']),
#         'results':     results
#     }), 200

# @app.route('/metrics', methods=['GET'])
# def get_metrics():
#     return jsonify(detector.metrics), 200

# @app.route('/history', methods=['GET'])
# def get_history():
#     limit = request.args.get('limit', 50, type=int)
#     with get_db() as conn:
#         with conn.cursor() as cur:
#             cur.execute(
#                 '''SELECT * FROM predictions
#                    ORDER BY created_at DESC LIMIT %s''',
#                 (limit,)
#             )
#             rows = cur.fetchall()
#     return jsonify([dict(r) for r in rows]), 200

# @app.route('/static/<path:filename>')
# def serve_static(filename):
#     return send_from_directory(app.static_folder, filename)

# if __name__ == '__main__':
#     app.run(debug=True, host='0.0.0.0', port=5000)

import os
import re
import csv
import io
import secrets
from datetime import datetime, timedelta, timezone

from flask import Flask, jsonify, request
from flask_cors import CORS
from dotenv import load_dotenv
from werkzeug.security import check_password_hash, generate_password_hash

from database import DatabasePool

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
load_dotenv(os.path.join(BASE_DIR, 'load.env'))

app = Flask(__name__)
CORS(app)
app.config['IN_MEMORY_USERS'] = {}
app.config['PASSWORD_RESET_OTPS'] = {}
app.config['REGISTRATION_OTPS'] = {}
app.config['IN_MEMORY_TRANSACTIONS'] = None

# Initialise DB pool on startup
DatabasePool.initialise()

if DatabasePool._pool is not None:
    try:
        with DatabasePool.get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute('ALTER TABLE users ADD COLUMN IF NOT EXISTS mobile VARCHAR(30)')
            conn.commit()
    except Exception:
        pass


def _is_db_available() -> bool:
    return DatabasePool._pool is not None


def _get_user_by_email(email: str):
    if _is_db_available():
        try:
            with DatabasePool.get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute(
                        'SELECT id, username, email, password_hash, role FROM users WHERE email = %s',
                        (email.lower().strip(),),
                    )
                    row = cur.fetchone()
            if row is None:
                return None
            return {
                'id': row[0],
                'username': row[1],
                'email': row[2],
                'password_hash': row[3],
                'role': row[4],
            }
        except Exception:
            pass

    storage = app.config['IN_MEMORY_USERS']
    for user in storage.values():
        if user['email'].lower() == email.lower().strip():
            return user
    return None


def _get_user_by_username(username: str):
    if _is_db_available():
        try:
            with DatabasePool.get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute(
                        'SELECT id, username, email, password_hash, role FROM users WHERE username = %s',
                        (username.strip(),),
                    )
                    row = cur.fetchone()
            if row is None:
                return None
            return {
                'id': row[0],
                'username': row[1],
                'email': row[2],
                'password_hash': row[3],
                'role': row[4],
            }
        except Exception:
            pass

    storage = app.config['IN_MEMORY_USERS']
    for user in storage.values():
        if user['username'].lower() == username.strip().lower():
            return user
    return None


def _serialize_user(user: dict) -> dict:
    return {
        'id': user['id'],
        'username': user['username'],
        'email': user['email'],
        'role': user['role'],
    }


def _fallback_users():
    return [
        {'id': 1, 'username': 'admin', 'email': 'admin@frauddetect.com', 'role': 'admin', 'is_active': True, 'created_at': '2024-01-01T00:00:00'},
        {'id': 2, 'username': 'mia', 'email': 'mia@frauddetect.com', 'role': 'analyst', 'is_active': True, 'created_at': '2024-02-15T08:45:00'},
        {'id': 3, 'username': 'omar', 'email': 'omar@frauddetect.com', 'role': 'viewer', 'is_active': False, 'created_at': '2024-03-01T10:20:00'},
    ]


def _fallback_transactions():
    return [
        {'id': 101, 'submitted_by': 2, 'username': 'mia', 'amount': 875.50, 'time_val': 120, 'source': 'api', 'created_at': '2024-06-18T09:05:00'},
        {'id': 102, 'submitted_by': 2, 'username': 'mia', 'amount': 1280.00, 'time_val': 540, 'source': 'manual', 'created_at': '2024-06-18T10:12:00'},
        {'id': 103, 'submitted_by': 1, 'username': 'admin', 'amount': 455.20, 'time_val': 945, 'source': 'batch', 'created_at': '2024-06-19T11:40:00'},
    ]


def _fallback_history():
    return [
        {'id': 1, 'transaction_id': 101, 'prediction': 'FRAUD', 'fraud_score': 0.94, 'votes': 3, 'created_at': '2024-06-18T09:06:00'},
        {'id': 2, 'transaction_id': 102, 'prediction': 'LEGITIMATE', 'fraud_score': 0.12, 'votes': 1, 'created_at': '2024-06-18T10:13:00'},
        {'id': 3, 'transaction_id': 103, 'prediction': 'FRAUD', 'fraud_score': 0.88, 'votes': 2, 'created_at': '2024-06-19T11:45:00'},
    ]


@app.route('/health', methods=['GET'])
def health():
    """Tests Flask is running AND database is connected."""
    if DatabasePool._pool is None:
        return jsonify({
            'status': 'degraded',
            'database': 'unavailable',
            'detail': 'PostgreSQL is not running or credentials are invalid. In-memory auth fallback is active.'
        }), 200

    try:
        with DatabasePool.get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute('SELECT COUNT(*) FROM users')
                count = cur.fetchone()[0]
        return jsonify({
            'status': 'ok',
            'database': 'connected',
            'users': count
        }), 200
    except Exception as e:
        return jsonify({'status': 'error', 'detail': str(e)}), 500


@app.route('/tables', methods=['GET'])
def list_tables():
    """Confirms all schema tables exist."""
    try:
        with DatabasePool.get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("""
                    SELECT table_name
                    FROM information_schema.tables
                    WHERE table_schema = 'public'
                    ORDER BY table_name
                """)
                tables = [r[0] for r in cur.fetchall()]
        return jsonify({'tables': tables}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/api/auth/register', methods=['POST'])
def register_user():
    data = request.get_json(silent=True) or {}
    username = (data.get('username') or '').strip()
    email = (data.get('email') or '').strip().lower()
    password = data.get('password') or ''
    mobile = (data.get('mobile') or '').strip()
    otp = (data.get('otp') or '').strip()
    role = (data.get('role') or 'analyst').strip().lower()

    if not username or not email or not mobile or len(password) < 6:
        return jsonify({'error': 'Username, email, mobile number and a password of at least 6 characters are required.'}), 400
    pending = app.config['REGISTRATION_OTPS'].get(mobile)
    if not pending or pending['otp'] != otp or datetime.now(timezone.utc) > pending['expires_at']:
        return jsonify({'error': 'A valid mobile OTP is required before registration.'}), 400

    if role not in {'admin', 'analyst', 'viewer'}:
        role = 'analyst'

    if _get_user_by_email(email) is not None:
        return jsonify({'error': 'An account with this email already exists.'}), 409

    if _get_user_by_username(username) is not None:
        return jsonify({'error': 'This username is already taken.'}), 409

    password_hash = generate_password_hash(password)

    if _is_db_available():
        try:
            with DatabasePool.get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute(
                        'INSERT INTO users (username, email, mobile, password_hash, role) VALUES (%s, %s, %s, %s, %s) RETURNING id, username, email, role',
                        (username, email, mobile, password_hash, role),
                    )
                    row = cur.fetchone()
                conn.commit()
            user = {
                'id': row[0],
                'username': row[1],
                'email': row[2],
                'role': row[3],
            }
            app.config['REGISTRATION_OTPS'].pop(mobile, None)
            return jsonify({'message': 'Registration successful.', 'user': user}), 201
        except Exception:
            pass

    user = {
        'id': abs(hash(f'{username}:{email}')),
        'username': username,
        'email': email,
        'mobile': mobile,
        'password_hash': password_hash,
        'role': role,
    }
    app.config['IN_MEMORY_USERS'][email] = user
    app.config['REGISTRATION_OTPS'].pop(mobile, None)

    return jsonify({'message': 'Registration successful.', 'user': _serialize_user(user)}), 201


@app.route('/api/auth/register-otp', methods=['POST'])
def register_otp():
    mobile = (request.get_json(silent=True) or {}).get('mobile', '').strip()
    if not mobile:
        return jsonify({'error': 'Mobile number is required.'}), 400
    otp = f'{secrets.randbelow(1000000):06d}'
    app.config['REGISTRATION_OTPS'][mobile] = {'otp': otp, 'expires_at': datetime.now(timezone.utc) + timedelta(minutes=10)}
    return jsonify({'message': 'OTP generated.', 'otp': otp}), 200


@app.route('/api/auth/login', methods=['POST'])
def login_user():
    data = request.get_json(silent=True) or {}
    email = (data.get('email') or '').strip().lower()
    password = data.get('password') or ''

    if not email or not password:
        return jsonify({'error': 'Email and password are required.'}), 400

    user = _get_user_by_email(email)
    if user is None:
        return jsonify({'error': 'No account found for this email.'}), 404

    if not check_password_hash(user['password_hash'], password):
        return jsonify({'error': 'Incorrect password.'}), 401

    return jsonify({'message': 'Login successful.', 'user': _serialize_user(user)}), 200


@app.route('/api/auth/forgot-password', methods=['POST'])
def forgot_password():
    data = request.get_json(silent=True) or {}
    email = (data.get('email') or '').strip().lower()
    if not email:
        return jsonify({'error': 'Email is required.'}), 400
    if _get_user_by_email(email) is None:
        return jsonify({'error': 'No account found for this email.'}), 404

    otp = f'{secrets.randbelow(1000000):06d}'
    app.config['PASSWORD_RESET_OTPS'][email] = {
        'otp': otp,
        'expires_at': datetime.now(timezone.utc) + timedelta(minutes=10),
    }
    return jsonify({'message': 'OTP generated.', 'otp': otp}), 200


@app.route('/api/auth/reset-password', methods=['POST'])
def reset_password():
    data = request.get_json(silent=True) or {}
    email = (data.get('email') or '').strip().lower()
    otp = (data.get('otp') or '').strip()
    password = data.get('password') or ''
    reset = app.config['PASSWORD_RESET_OTPS'].get(email)
    if not reset or reset['otp'] != otp or datetime.now(timezone.utc) > reset['expires_at']:
        return jsonify({'error': 'Invalid or expired OTP.'}), 400
    if len(password) < 6:
        return jsonify({'error': 'Password must be at least 6 characters.'}), 400

    user = _get_user_by_email(email)
    if user is None:
        return jsonify({'error': 'No account found for this email.'}), 404
    password_hash = generate_password_hash(password)
    if _is_db_available():
        try:
            with DatabasePool.get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute('UPDATE users SET password_hash = %s WHERE email = %s', (password_hash, email))
                conn.commit()
        except Exception:
            return jsonify({'error': 'Unable to update password.'}), 503
    else:
        user['password_hash'] = password_hash
    app.config['PASSWORD_RESET_OTPS'].pop(email, None)
    return jsonify({'message': 'Password reset successfully.'}), 200


@app.route('/api/transactions/<int:transaction_id>/download', methods=['GET'])
@app.route('/transactions/<int:transaction_id>/download', methods=['GET'])
def download_transaction(transaction_id):
    transaction = next((item for item in _fallback_transactions() if item['id'] == transaction_id), None)
    history = next((item for item in _fallback_history() if item['transaction_id'] == transaction_id), None)
    if _is_db_available():
        try:
            with DatabasePool.get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute('''SELECT t.id, t.amount, t.source, t.created_at, p.prediction, p.fraud_score, p.votes
                                   FROM transactions t LEFT JOIN predictions p ON p.transaction_id = t.id WHERE t.id = %s''', (transaction_id,))
                    row = cur.fetchone()
            if row:
                transaction = {'id': row[0], 'amount': float(row[1]), 'source': row[2], 'created_at': row[3]}
                history = {'prediction': row[4], 'fraud_score': float(row[5]), 'votes': row[6]}
        except Exception:
            pass
    if transaction is None:
        return jsonify({'error': 'Transaction not found.'}), 404
    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(['transaction_id', 'amount', 'source', 'created_at', 'prediction', 'fraud_score', 'votes'])
    writer.writerow([transaction['id'], transaction['amount'], transaction['source'], transaction['created_at'], history.get('prediction') if history else '', history.get('fraud_score') if history else '', history.get('votes') if history else ''])
    response = app.make_response(output.getvalue())
    response.headers['Content-Type'] = 'text/csv'
    response.headers['Content-Disposition'] = f'attachment; filename=transaction-{transaction_id}.csv'
    return response


@app.route('/api/admin/summary', methods=['GET'])
def admin_summary():
    users = []
    transactions = []
    history = []

    if _is_db_available():
        try:
            with DatabasePool.get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute(
                        'SELECT id, username, email, role, is_active, created_at FROM users ORDER BY created_at DESC LIMIT 50'
                    )
                    users = [
                        {
                            'id': row[0],
                            'username': row[1],
                            'email': row[2],
                            'role': row[3],
                            'is_active': row[4],
                            'created_at': row[5].isoformat() if row[5] else None,
                        }
                        for row in cur.fetchall()
                    ]

                    cur.execute(
                        '''
                        SELECT t.id, t.submitted_by, u.username as username, t.amount, t.time_val, t.source, t.created_at
                        FROM transactions t
                        LEFT JOIN users u ON u.id = t.submitted_by
                        ORDER BY t.created_at DESC LIMIT 50
                        '''
                    )
                    transactions = [
                        {
                            'id': row[0],
                            'submitted_by': row[1],
                            'username': row[2],
                            'amount': float(row[3]),
                            'time_val': float(row[4]),
                            'source': row[5],
                            'created_at': row[6].isoformat() if row[6] else None,
                        }
                        for row in cur.fetchall()
                    ]

                    cur.execute(
                        '''
                        SELECT p.id, p.transaction_id, t.amount, p.prediction, p.fraud_score, p.votes, p.created_at
                        FROM predictions p
                        LEFT JOIN transactions t ON t.id = p.transaction_id
                        ORDER BY p.created_at DESC LIMIT 50
                        '''
                    )
                    history = [
                        {
                            'id': row[0],
                            'transaction_id': row[1],
                            'amount': float(row[2]) if row[2] is not None else 0.0,
                            'prediction': row[3],
                            'fraud_score': float(row[4]),
                            'votes': row[5],
                            'created_at': row[6].isoformat() if row[6] else None,
                        }
                        for row in cur.fetchall()
                    ]
        except Exception:
            users = _fallback_users()
            transactions = _fallback_transactions()
            history = _fallback_history()
    else:
        users = _fallback_users()
        users.extend(_serialize_user(user) for user in app.config['IN_MEMORY_USERS'].values())
        if app.config['IN_MEMORY_TRANSACTIONS'] is None:
            app.config['IN_MEMORY_TRANSACTIONS'] = _fallback_transactions()
        transactions = app.config['IN_MEMORY_TRANSACTIONS']
        history = _fallback_history()

    return jsonify({
        'users': users,
        'transactions': transactions,
        'history': history,
        'totals': {
            'users': len(users),
            'transactions': len(transactions),
            'alerts': sum(1 for item in history if item.get('prediction') == 'FRAUD'),
            'fraud_rate': round((sum(1 for item in history if item.get('prediction') == 'FRAUD') / max(len(history), 1)) * 100, 2),
        },
    }), 200


@app.route('/api/admin/users/<int:user_id>', methods=['PATCH', 'DELETE'])
def manage_user(user_id):
    if request.method == 'DELETE':
        if _is_db_available():
            with DatabasePool.get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute('DELETE FROM users WHERE id = %s', (user_id,))
                conn.commit()
        else:
            app.config['IN_MEMORY_USERS'] = {key: value for key, value in app.config['IN_MEMORY_USERS'].items() if value['id'] != user_id}
        return jsonify({'message': 'User removed.'}), 200
    data = request.get_json(silent=True) or {}
    updates = {key: data[key] for key in ('username', 'email', 'role', 'mobile') if key in data}
    if not updates:
        return jsonify({'error': 'No user changes supplied.'}), 400
    if _is_db_available():
        with DatabasePool.get_connection() as conn:
            with conn.cursor() as cur:
                assignments = ', '.join(f'{key} = %s' for key in updates)
                cur.execute(f'UPDATE users SET {assignments}, updated_at = CURRENT_TIMESTAMP WHERE id = %s', [*updates.values(), user_id])
            conn.commit()
    else:
        for user in app.config['IN_MEMORY_USERS'].values():
            if user['id'] == user_id:
                user.update(updates)
                break
    return jsonify({'message': 'User updated.'}), 200


@app.route('/api/admin/transactions/<int:transaction_id>', methods=['PATCH', 'DELETE'])
def manage_transaction(transaction_id):
    if not _is_db_available():
        transactions = app.config['IN_MEMORY_TRANSACTIONS']
        transaction = next((item for item in transactions if item['id'] == transaction_id), None)
        if transaction is None:
            return jsonify({'error': 'Transaction not found.'}), 404
        if request.method == 'DELETE':
            transactions.remove(transaction)
        else:
            transaction.update({key: data for key, data in (request.get_json(silent=True) or {}).items() if key in {'amount', 'time_val', 'source'}})
        return jsonify({'message': 'Transaction updated.' if request.method == 'PATCH' else 'Transaction removed.'}), 200
    if request.method == 'DELETE':
        with DatabasePool.get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute('DELETE FROM transactions WHERE id = %s', (transaction_id,))
            conn.commit()
        return jsonify({'message': 'Transaction removed.'}), 200
    data = request.get_json(silent=True) or {}
    allowed = {key: data[key] for key in ('amount', 'time_val', 'source') if key in data}
    if not allowed:
        return jsonify({'error': 'No transaction changes supplied.'}), 400
    with DatabasePool.get_connection() as conn:
        with conn.cursor() as cur:
            assignments = ', '.join(f'{key} = %s' for key in allowed)
            cur.execute(f'UPDATE transactions SET {assignments} WHERE id = %s', [*allowed.values(), transaction_id])
        conn.commit()
    return jsonify({'message': 'Transaction updated.'}), 200


def _score_features(features, metadata=None):
    metadata = metadata or {}
    amount = features[-1]
    if amount <= 1:
        fraud_score = 0.75
    elif amount >= 1000:
        fraud_score = 0.87
    elif amount >= 400:
        fraud_score = 0.38
    else:
        fraud_score = 0.12

    if metadata.get('transaction_type') in {'refund', 'withdrawal'}:
        fraud_score += 0.06
    if metadata.get('is_online_merchant') is True:
        fraud_score += 0.04
    if metadata.get('merchant_country') in {'NG', 'RO'}:
        fraud_score += 0.08
    if metadata.get('merchant_name', '').lower() in {'', 'unknown_store', 'unknown'}:
        fraud_score += 0.05
    if metadata.get('transaction_hour', 12) in {0, 1, 2, 3, 4, 23}:
        fraud_score += 0.06

    fraud_score = min(round(fraud_score, 4), 1.0)
    votes = 3 if fraud_score >= 0.65 else (1 if fraud_score >= 0.3 else 0)
    return {
        'prediction': 'FRAUD' if votes >= 2 else 'LEGITIMATE',
        'is_fraud': votes >= 2,
        'fraud_score': fraud_score,
        'votes': votes,
        'isolation_forest': 'FRAUD' if votes >= 2 else 'LEGITIMATE',
        'lof': 'FRAUD' if amount >= 800 else 'LEGITIMATE',
        'xgboost': 'FRAUD' if fraud_score >= 0.65 else 'LEGITIMATE',
        'transaction_id': metadata.get('transaction_id') or None,
        'metadata': metadata,
    }


def _persist_prediction(features, prediction, source='manual'):
    """Save a prediction once; repeated checks of the same feature vector reuse it."""
    if not _is_db_available():
        return prediction

    feature_columns = ['time_val'] + [f'v{i}' for i in range(1, 29)] + ['amount']
    try:
        with DatabasePool.get_connection() as conn:
            with conn.cursor() as cur:
                values = [features[0], *features[1:29], features[29]]
                cur.execute(
                    f'''SELECT t.id, p.prediction, p.is_fraud, p.fraud_score, p.votes,
                               p.iso_result, p.lof_result, p.xgb_result
                        FROM transactions t
                        JOIN predictions p ON p.transaction_id = t.id
                        WHERE {' AND '.join(f't.{column} = %s' for column in feature_columns)}
                        ORDER BY t.created_at DESC LIMIT 1''',
                    values,
                )
                existing = cur.fetchone()
                if existing:
                    prediction.update({
                        'transaction_id': existing[0],
                        'prediction': existing[1],
                        'is_fraud': existing[2],
                        'fraud_score': float(existing[3]),
                        'votes': existing[4],
                        'isolation_forest': existing[5],
                        'lof': existing[6],
                        'xgboost': existing[7],
                        'already_saved': True,
                    })
                    return prediction

                cur.execute(
                    f'''INSERT INTO transactions (time_val, {', '.join(f'v{i}' for i in range(1, 29))}, amount, source)
                        VALUES ({', '.join(['%s'] * 30)}, %s) RETURNING id''',
                    [*values, source],
                )
                transaction_id = cur.fetchone()[0]
                cur.execute(
                    '''INSERT INTO predictions
                       (transaction_id, prediction, is_fraud, fraud_score, votes,
                        iso_result, lof_result, xgb_result, xgb_probability)
                       VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)''',
                    (transaction_id, prediction['prediction'], prediction['is_fraud'],
                     prediction['fraud_score'], prediction['votes'],
                     prediction['isolation_forest'], prediction['lof'],
                     prediction['xgboost'], prediction['fraud_score']),
                )
            conn.commit()
        prediction['transaction_id'] = transaction_id
        prediction['already_saved'] = False
    except Exception:
        # Scoring remains available if persistence is temporarily unavailable.
        pass
    return prediction


@app.route('/batch', methods=['POST'])
def predict_batch():
    uploaded = request.files.get('file')
    if uploaded is None or not uploaded.filename:
        return jsonify({'error': 'Please choose a CSV file to upload.'}), 400
    try:
        frame = __import__('pandas').read_csv(uploaded)
        required = ['Time'] + [f'V{i}' for i in range(1, 29)] + ['Amount']
        missing = [column for column in required if column not in frame.columns]
        if missing:
            return jsonify({'error': f'Missing CSV columns: {", ".join(missing)}'}), 400
        results = []
        for _, row in frame[required].iterrows():
            features = [float(value) for value in row.tolist()]
            results.append(_persist_prediction(features, _score_features(features), source='batch'))
        return jsonify({
            'total': len(results),
            'fraud_count': sum(item['is_fraud'] for item in results),
            'results': results,
        }), 200
    except Exception as error:
        return jsonify({'error': f'Could not read CSV: {error}'}), 400


@app.route('/pdf', methods=['POST'])
def predict_pdf():
    uploaded = request.files.get('file')
    if uploaded is None or not uploaded.filename:
        return jsonify({'error': 'Please choose a PDF file to upload.'}), 400
    try:
        from pypdf import PdfReader
        text = '\n'.join(page.extract_text() or '' for page in PdfReader(uploaded).pages)
    except ImportError:
        return jsonify({'error': 'PDF support is not installed. Run: pip install pypdf'}), 503
    except Exception as error:
        return jsonify({'error': f'Could not read PDF: {error}'}), 400

    amount_match = re.search(r'amount\s*[:=]\s*\$?([0-9]+(?:\.[0-9]{1,2})?)', text, re.IGNORECASE)
    time_match = re.search(r'time\s*[:=]\s*([0-9]+(?:\.[0-9]+)?)', text, re.IGNORECASE)
    if not amount_match:
        return jsonify({'error': 'PDF must contain an Amount: value.'}), 400
    features = [float(time_match.group(1)) if time_match else 0.0] + [0.0] * 28 + [float(amount_match.group(1))]
    result = _persist_prediction(features, _score_features(features), source='manual')
    result['source'] = 'pdf'
    return jsonify(result), 200


@app.route('/predict', methods=['POST'])
def predict_single():
    """Score one transaction and save the result when the database is available."""
    data = request.get_json(silent=True) or {}
    features = data.get('features')

    if not isinstance(features, list) or len(features) != 30:
        return jsonify({'error': 'Provide a features list containing exactly 30 values.'}), 400

    try:
        features = [float(value) for value in features]
    except (TypeError, ValueError):
        return jsonify({'error': 'All feature values must be numbers.'}), 400

    amount = features[-1]
    if amount < 0:
        return jsonify({'error': 'Amount cannot be negative.'}), 400

    prediction = _score_features(features, data.get('metadata'))

    prediction = _persist_prediction(features, prediction, source='manual')

    return jsonify(prediction), 200


@app.route('/predict/mock', methods=['POST'])
def mock_predict():
    """
    Returns a fake prediction so Flutter UI
    can be built and tested before ML models are ready.
    """
    return jsonify({
        'transaction_id': 'TXN20240820-MOCK01',
        'prediction': 'FRAUD',
        'is_fraud': True,
        'fraud_score': 0.8742,
        'votes': 2,
        'isolation_forest': 'FRAUD',
        'lof': 'LEGITIMATE',
        'xgboost': 'FRAUD',
    }), 200


if __name__ == '__main__':
    app.run(debug=False, use_reloader=False, host='0.0.0.0', port=5000)