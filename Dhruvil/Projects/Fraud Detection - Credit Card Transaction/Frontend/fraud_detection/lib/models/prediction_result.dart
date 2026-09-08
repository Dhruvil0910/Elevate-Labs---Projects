class PredictionResult {
  final String prediction;
  final bool isFraud;
  final double fraudScore;
  final int votes;
  final String isolationForest;
  final String lof;
  final String xgboost;

  PredictionResult.fromJson(Map<String, dynamic> j)
      : prediction      = j['prediction'],
        isFraud         = j['is_fraud'],
        fraudScore      = (j['fraud_score'] as num).toDouble(),
        votes           = j['votes'],
        isolationForest = j['isolation_forest'],
        lof             = j['lof'],
        xgboost         = j['xgboost'];
}