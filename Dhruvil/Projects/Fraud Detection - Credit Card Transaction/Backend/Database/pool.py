import logging
from contextlib import contextmanager
from psycopg2 import pool, OperationalError, InterfaceError
from config import Config

logger = logging.getLogger(__name__)

class DatabasePool:
    """
    Thread-safe PostgreSQL connection pool.
    Single instance shared across all Flask requests.
    """
    _pool = None

    @classmethod
    def initialise(cls):
        """Call once when Flask app starts."""
        if cls._pool is not None:
            return True  # already initialised

        try:
            cls._pool = pool.ThreadedConnectionPool(
                minconn=Config.DB_MIN_CONN,
                maxconn=Config.DB_MAX_CONN,
                host=Config.DB_HOST,
                port=Config.DB_PORT,
                dbname=Config.DB_NAME,
                user=Config.DB_USER,
                password=Config.DB_PASSWORD,
                # Keep connections alive + auto-reconnect
                keepalives=1,
                keepalives_idle=30,
                keepalives_interval=5,
                keepalives_count=3,
                connect_timeout=5,
            )
            logger.info(
                f"Pool ready — min={Config.DB_MIN_CONN} "
                f"max={Config.DB_MAX_CONN} "
                f"db={Config.DB_NAME}@{Config.DB_HOST}"
            )
            return True
        except Exception as e:
            cls._pool = None
            logger.warning(f"Database unavailable: {e}. App will run in degraded mode.")
            return False

    @classmethod
    def close_all(cls):
        """Call on app shutdown to release all connections."""
        if cls._pool:
            cls._pool.closeall()
            cls._pool = None
            logger.info("Pool closed.")

    @classmethod
    @contextmanager
    def get_connection(cls):
        """
        Context manager — borrows a connection from pool,
        returns it automatically when the block exits,
        even if an exception occurs.

        Usage:
            with DatabasePool.get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute(...)
                conn.commit()
        """
        if cls._pool is None:
            raise RuntimeError("Pool not initialised. Call DatabasePool.initialise() first.")

        conn = None
        try:
            conn = cls._pool.getconn()

            # Validate connection is still alive — reconnect if stale
            if conn.closed:
                cls._pool.putconn(conn, close=True)
                conn = cls._pool.getconn()

            yield conn

        except (OperationalError, InterfaceError) as e:
            # Network drop or DB restart — rollback and re-raise
            logger.warning(f"DB connection error: {e}")
            if conn:
                try:
                    conn.rollback()
                except Exception:
                    pass
            raise

        except Exception as e:
            # Any other error — rollback
            if conn:
                try:
                    conn.rollback()
                except Exception:
                    pass
            raise

        finally:
            # Always return connection to pool — never leave it hanging
            if conn:
                cls._pool.putconn(conn)