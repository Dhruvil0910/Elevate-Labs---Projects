import joblib, json, os
import numpy as np
import matplotlib.pyplot as plt
from sklearn.ensemble import IsolationForest
from sklearn.neighbors import LocalOutlierFactor
from sklearn.metrics import (classification_report, confusion_matrix,
                             roc_auc_score, roc_curve)
from xgboost import XGBClassifier
from preprocess import load_and_prepare

MODELS_DIR = os.path.join(os.path.dirname(__file__), 'models')
os.makedirs(MODELS_DIR, exist_ok=True)

X_train, X_test, y_train, y_test, scaler = load_and_prepare('../creditcard.csv')

# 1. Isolation Forest
iso = IsolationForest(n_estimators=100, contamination=0.002, random_state=42)
iso.fit(X_train)
iso_preds = (iso.predict(X_test) == -1).astype(int)

# 2. Local Outlier Factor (novelty=True allows predict on new data)
lof = LocalOutlierFactor(n_neighbors=20, contamination=0.002, novelty=True)
lof.fit(X_train)
lof_preds = (lof.predict(X_test) == -1).astype(int)

# 3. XGBoost
ratio = (y_train == 0).sum() / (y_train == 1).sum()
xgb = XGBClassifier(
    n_estimators=200, max_depth=6, learning_rate=0.1,
    scale_pos_weight=ratio, eval_metric='logloss', random_state=42
)
xgb.fit(X_train, y_train)
xgb_proba = xgb.predict_proba(X_test)[:, 1]
xgb_preds = (xgb_proba >= 0.5).astype(int)

# 4. ROC Curve — save as static image served by Flask
fpr, tpr, _ = roc_curve(y_test, xgb_proba)
auc_score   = roc_auc_score(y_test, xgb_proba)
plt.figure(figsize=(7, 5))
plt.plot(fpr, tpr, color='#2a78d6', label=f'AUC = {auc_score:.4f}')
plt.plot([0,1],[0,1],'--', color='#888')
plt.xlabel('False Positive Rate'); plt.ylabel('True Positive Rate')
plt.title('XGBoost ROC Curve'); plt.legend()
plt.savefig('../static/roc_curve.png', dpi=120, bbox_inches='tight')
plt.close()

# 5. Save everything
joblib.dump(iso,    f'{MODELS_DIR}/isolation_forest.pkl')
joblib.dump(lof,    f'{MODELS_DIR}/lof.pkl')
joblib.dump(xgb,    f'{MODELS_DIR}/xgboost.pkl')
joblib.dump(scaler, f'{MODELS_DIR}/scaler.pkl')

report = classification_report(y_test, xgb_preds, output_dict=True)
metrics = {
    'auc':              round(auc_score, 4),
    'accuracy':         round(report['accuracy'], 4),
    'precision_fraud':  round(report['1']['precision'], 4),
    'recall_fraud':     round(report['1']['recall'], 4),
    'f1_fraud':         round(report['1']['f1-score'], 4),
    'confusion_matrix': confusion_matrix(y_test, xgb_preds).tolist()
}
with open(f'{MODELS_DIR}/metrics.json', 'w') as f:
    json.dump(metrics, f)

print(f"Done. AUC = {auc_score:.4f}")