import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  final _otp = TextEditingController();
  final _password = TextEditingController();
  bool _otpSent = false;
  bool _loading = false;
  String _message = '';
  String _error = '';

  Future<void> _sendOtp() async {
    if (_email.text.trim().isEmpty) {
      setState(() => _error = 'Enter your account email.');
      return;
    }
    setState(() { _loading = true; _error = ''; _message = ''; });
    try {
      final otp = await AuthService.requestPasswordReset(_email.text);
      if (!mounted) return;
      setState(() {
        _otpSent = true;
        _message = 'OTP sent. Development OTP: $otp';
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reset() async {
    if (_otp.text.trim().isEmpty || _password.text.length < 6) {
      setState(() => _error = 'Enter the OTP and a password of at least 6 characters.');
      return;
    }
    setState(() { _loading = true; _error = ''; _message = ''; });
    try {
      await AuthService.resetPassword(email: _email.text, otp: _otp.text, password: _password.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset successfully.')));
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _otp.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recover password')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('Reset your password', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('Verify your email with a one-time password.', style: TextStyle(color: Color(0xFF6B7A99))),
              const SizedBox(height: 24),
              TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 12),
              if (_otpSent) ...[
                TextField(controller: _otp, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'OTP')),
                const SizedBox(height: 12),
                TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'New password')),
                const SizedBox(height: 12),
              ],
              if (_message.isNotEmpty) Text(_message, style: const TextStyle(color: Color(0xFF00E396))),
              if (_error.isNotEmpty) Text(_error, style: const TextStyle(color: Color(0xFFFF4560))),
              const SizedBox(height: 12),
              FilledButton(onPressed: _loading ? null : (_otpSent ? _reset : _sendOtp), child: _loading ? const CircularProgressIndicator() : Text(_otpSent ? 'Reset password' : 'Send OTP')),
            ]),
          ),
        ),
      ),
    );
  }
}
