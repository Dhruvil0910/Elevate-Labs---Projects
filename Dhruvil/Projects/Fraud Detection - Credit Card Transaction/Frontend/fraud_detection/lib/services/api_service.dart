import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:5000'; // change for device
  // On Android emulator use: http://10.0.2.2:5000
  // On real device use your machine's IP: http://192.168.x.x:5000

  // ── Single prediction ──────────────────────────────────────────────
    static Future<Map<String, dynamic>> predictSingle(
      List<double> features, {Map<String, dynamic>? metadata}) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/predict'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'features': features, 'metadata': metadata ?? {}}),
          )
          .timeout(const Duration(seconds: 8));
      final body = _decodeObject(res.body);
      if (res.statusCode == 200) return body;
      throw Exception(body['error'] ?? 'Prediction failed (${res.statusCode}).');
    } on FormatException {
      throw Exception('Server returned an invalid response.');
    } on http.ClientException {
      throw Exception('Cannot connect to the server.');
    } on TimeoutException {
      throw Exception('Server request timed out.');
    }
  }

  static Map<String, dynamic> _decodeObject(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Expected a JSON object.');
    }
    return decoded;
  }

  // ── Batch CSV prediction ───────────────────────────────────────────
  static Future<Map<String, dynamic>> predictBatch(File csvFile) async {
    return _uploadFile('/batch', csvFile, 'Batch upload failed');
  }

  static Future<Map<String, dynamic>> predictPdf(File pdfFile) async {
    return _uploadFile('/pdf', pdfFile, 'PDF upload failed');
  }

  static Future<Map<String, dynamic>> _uploadFile(
      String path, File file, String errorPrefix) async {
    try {
      final req = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'));
      req.files.add(await http.MultipartFile.fromPath('file', file.path));
      final streamed = await req.send().timeout(const Duration(seconds: 30));
      final res = await http.Response.fromStream(streamed);
      final body = _decodeObject(res.body);
      if (res.statusCode == 200) return body;
      throw Exception(body['error'] ?? '$errorPrefix (${res.statusCode}).');
    } on FormatException {
      throw Exception('Server returned an invalid response.');
    } on http.ClientException {
      throw Exception('Cannot connect to the server.');
    } on TimeoutException {
      throw Exception('File upload timed out.');
    }
  }

  // ── Model metrics ──────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getMetrics() async {
    final res = await http.get(Uri.parse('$baseUrl/metrics'));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load metrics');
  }

  // ── Prediction history ─────────────────────────────────────────────
  static Future<List<dynamic>> getHistory({int limit = 50}) async {
    final res = await http.get(Uri.parse('$baseUrl/history?limit=$limit'));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load history');
  }
}