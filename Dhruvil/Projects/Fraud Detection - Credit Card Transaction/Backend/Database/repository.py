import logging
from psycopg2.extras import RealDictCursor
from .pool import DatabasePool

logger = logging.getLogger(__name__)


class PredictionRepository:
    """All database operations for predictions table."""

    @staticmethod
    def save(amount, prediction, fraud_score, votes,
             iso_result, lof_result, xgb_result) -> dict:
        """Insert one prediction, return the saved row with id."""
        sql = '''
            INSERT INTO predictions
                (amount, prediction, fraud_score, votes,
                 iso_result, lof_result, xgb_result)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            RETURNING *
        '''
        with DatabasePool.get_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cur:
                cur.execute(sql, (amount, prediction, fraud_score,
                                  votes, iso_result, lof_result, xgb_result))
                row = cur.fetchone()
            conn.commit()
        logger.info(f"Saved prediction id={row['id']} → {prediction}")
        return dict(row)

    @staticmethod
    def save_batch(records: list) -> int:
        """
        Bulk insert — much faster than calling save() in a loop.
        records: list of tuples matching column order above.
        Returns count of inserted rows.
        """
        sql = '''
            INSERT INTO predictions
                (amount, prediction, fraud_score, votes,
                 iso_result, lof_result, xgb_result)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        '''
        with DatabasePool.get_connection() as conn:
            with conn.cursor() as cur:
                cur.executemany(sql, records)
                count = cur.rowcount
            conn.commit()
        logger.info(f"Batch inserted {count} predictions.")
        return count

    @staticmethod
    def get_history(limit: int = 50) -> list:
        """Fetch most recent predictions."""
        sql = '''
            SELECT * FROM predictions
            ORDER BY created_at DESC
            LIMIT %s
        '''
        with DatabasePool.get_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cur:
                cur.execute(sql, (limit,))
                rows = cur.fetchall()
        return [dict(r) for r in rows]

    @staticmethod
    def get_stats() -> dict:
        """Aggregate stats for the dashboard."""
        sql = '''
            SELECT
                COUNT(*)                                        AS total,
                COUNT(*) FILTER (WHERE prediction = 'FRAUD')   AS total_fraud,
                COUNT(*) FILTER (WHERE prediction = 'LEGITIMATE') AS total_legit,
                ROUND(AVG(fraud_score)::numeric, 4)             AS avg_fraud_score,
                ROUND(
                    COUNT(*) FILTER (WHERE prediction = 'FRAUD')
                    * 100.0 / NULLIF(COUNT(*), 0), 2
                )                                               AS fraud_percentage
            FROM predictions
        '''
        with DatabasePool.get_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cur:
                cur.execute(sql)
                row = cur.fetchone()
        return dict(row)