import 'dart:convert';

import 'package:http/http.dart' as http;

class AuthUser {
  final int id;
  final String username;
  final String email;
  final String role;

  const AuthUser({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as int,
      username: (json['username'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? 'analyst').toString(),
    );
  }
}

class AuthService {
  static const String baseUrl = 'http://localhost:5000';
  static const Duration _timeout = Duration(seconds: 8);

  static String _friendlyError(String error) {
    if (error.contains('Failed to host lookup')) {
      return 'Network error: Unable to connect to server.!';
    }
    if (error.contains('Connection refused')) {
      return 'Server connection failed.!';
    }
    if (error.contains('SocketException')) {
      return 'Network error. Check your connection!';
    }
    if (error.contains('No account found')) {
      return 'No account found with this email. Please sign up first.';
    }
    if (error.contains('Incorrect password')) {
      return 'Incorrect password. Please try again.';
    }
    if (error.contains('already exists')) {
      return 'Email or username already registered. Try logging in instead.';
    }
    if (error.contains('required')) {
      return 'Please fill in all required fields.';
    }
    return error;
  }

  static Future<AuthUser> register({
    required String username,
    required String email,
    required String password,
    required String role,
    required String mobile,
    required String otp,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': username,
              'email': email,
              'password': password,
              'role': role,
              'mobile': mobile,
              'otp': otp,
            }),
          )
          .timeout(_timeout, onTimeout: () {
        throw Exception('Request timed out. Server is not responding.');
      });

      Map<String, dynamic> body;
      try {
        body = jsonDecode(response.body);
      } catch (_) {
        throw Exception(
            'Server error: Invalid response. Check if backend is running correctly.');
      }

      if (response.statusCode >= 400) {
        throw Exception(body['error'] ?? 'Registration failed.');
      }

      return AuthUser.fromJson(body['user']);
    } catch (e) {
      throw Exception(_friendlyError(e.toString()));
    }
  }

  static Future<String> requestRegistrationOtp(String mobile) async {
    final response = await http.post(Uri.parse('$baseUrl/api/auth/register-otp'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'mobile': mobile})).timeout(_timeout);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) throw Exception(body['error'] ?? 'Could not send OTP.');
    return body['otp'].toString();
  }

  static Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'password': password,
            }),
          )
          .timeout(_timeout, onTimeout: () {
        throw Exception('Request timed out. Server is not responding.');
      });

      Map<String, dynamic> body;
      try {
        body = jsonDecode(response.body);
      } catch (_) {
        throw Exception(
            'Server error: Invalid response. Check if backend is running correctly.');
      }

      if (response.statusCode >= 400) {
        throw Exception(body['error'] ?? 'Login failed.');
      }

      return AuthUser.fromJson(body['user']);
    } catch (e) {
      throw Exception(_friendlyError(e.toString()));
    }
  }

  static Future<String> requestPasswordReset(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim()}),
    ).timeout(_timeout);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) throw Exception(body['error'] ?? 'Could not send OTP.');
    return (body['otp'] ?? '').toString();
  }

  static Future<void> resetPassword({required String email, required String otp, required String password}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim(), 'otp': otp.trim(), 'password': password}),
    ).timeout(_timeout);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) throw Exception(body['error'] ?? 'Could not reset password.');
  }

  static Future<Map<String, dynamic>> getAdminSummary() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/admin/summary'))
          .timeout(_timeout, onTimeout: () {
        throw Exception('Request timed out.');
      });

      Map<String, dynamic> body;
      try {
        body = jsonDecode(response.body);
      } catch (_) {
        throw Exception(
            'Server error: Invalid response. Check if backend is running correctly.');
      }

      if (response.statusCode >= 400) {
        throw Exception(body['error'] ?? 'Failed to load admin data.');
      }
      return body;
    } catch (e) {
      throw Exception(_friendlyError(e.toString()));
    }
  }

  static Future<void> deleteAdminUser(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/api/admin/users/$id')).timeout(_timeout);
    if (response.statusCode >= 400) throw Exception('Could not remove user.');
  }

  static Future<void> deleteAdminTransaction(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/api/admin/transactions/$id')).timeout(_timeout);
    if (response.statusCode >= 400) throw Exception('Could not remove transaction.');
  }

  static Future<void> updateAdminUser(int id, Map<String, dynamic> changes) async {
    final response = await http.patch(Uri.parse('$baseUrl/api/admin/users/$id'), headers: {'Content-Type': 'application/json'}, body: jsonEncode(changes)).timeout(_timeout);
    if (response.statusCode >= 400) throw Exception('Could not update user.');
  }

  static Future<void> updateAdminTransaction(int id, Map<String, dynamic> changes) async {
    final response = await http.patch(Uri.parse('$baseUrl/api/admin/transactions/$id'), headers: {'Content-Type': 'application/json'}, body: jsonEncode(changes)).timeout(_timeout);
    if (response.statusCode >= 400) throw Exception('Could not update transaction.');
  }
}
