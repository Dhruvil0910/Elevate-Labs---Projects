import joblib, json, os
import pandas as pd

BASE = os.path.dirname(__file__)

class FraudDetector:
    """Singleton — models loaded once when Flask starts."""
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._load_models()
        return cls._instance

    def _load_models(self):
        m = f'{BASE}/models'
        self.scaler  = joblib.load(f'{m}/scaler.pkl')
        self.iso     = joblib.load(f'{m}/isolation_forest.pkl')
        self.lof     = joblib.load(f'{m}/lof.pkl')
        self.xgb     = joblib.load(f'{m}/xgboost.pkl')
        with open(f'{m}/metrics.json') as f:
            self.metrics = json.load(f)

    # Feature column order must match training
    FEATURE_COLS = ['Time'] + [f'V{i}' for i in range(1, 29)] + ['Amount']

    def predict(self, feature_values: list) -> dict:
        X = pd.DataFrame([feature_values], columns=self.FEATURE_COLS)
        X[['Amount', 'Time']] = self.scaler.transform(X[['Amount', 'Time']])

        iso_flag  = int(self.iso.predict(X)[0] == -1)
        lof_flag  = int(self.lof.predict(X)[0] == -1)
        xgb_proba = float(self.xgb.predict_proba(X)[0][1])
        xgb_flag  = int(xgb_proba >= 0.5)

        votes = iso_flag + lof_flag + xgb_flag
        label = 'FRAUD' if votes >= 2 else 'LEGITIMATE'

        return {
            'prediction':       label,
            'is_fraud':         label == 'FRAUD',
            'fraud_score':      round(xgb_proba, 4),
            'votes':            votes,
            'isolation_forest': 'FRAUD' if iso_flag else 'LEGITIMATE',
            'lof':              'FRAUD' if lof_flag else 'LEGITIMATE',
            'xgboost':          'FRAUD' if xgb_flag else 'LEGITIMATE',
        }

    def predict_batch(self, df: pd.DataFrame) -> list:
        return [self.predict(row.tolist()) for _, row in df[self.FEATURE_COLS].iterrows()]