import 'package:flutter/material.dart';
import '../models/prediction_result.dart';

class ResultScreen extends StatelessWidget {
  final PredictionResult result;
  const ResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final isFraud = result.isFraud;
    final color   = isFraud ? Colors.red.shade700 : Colors.green.shade700;
    final icon    = isFraud ? Icons.warning_amber_rounded : Icons.check_circle;

    return Scaffold(
      appBar: AppBar(title: const Text('Result')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            Icon(icon, size: 80, color: color),
            const SizedBox(height: 16),
            Text(result.prediction,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 8),
            Text('Fraud probability: ${(result.fraudScore * 100).toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 32),
            // Per-model breakdown
            _modelRow('Isolation Forest', result.isolationForest),
            _modelRow('Local Outlier Factor', result.lof),
            _modelRow('XGBoost', result.xgboost),
            const SizedBox(height: 16),
            Text('Votes: ${result.votes}/3 flagged as fraud',
                style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _modelRow(String name, String verdict) {
    final fraud = verdict == 'FRAUD';
    return ListTile(
      leading: Icon(fraud ? Icons.flag : Icons.check,
          color: fraud ? Colors.red : Colors.green),
      title: Text(name),
      trailing: Text(verdict,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: fraud ? Colors.red : Colors.green)),
    );
  }
}