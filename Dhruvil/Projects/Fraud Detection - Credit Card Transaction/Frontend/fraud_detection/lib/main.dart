import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'screens/predict_screen.dart';
import 'services/auth_service.dart';
import 'screens/forgot_password_screen.dart';

void main() => runApp(const FraudDetectionApp());

class FraudDetectionApp extends StatelessWidget {
  const FraudDetectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SentinelFD',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0A0F1E),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00D4FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  AuthUser? _user;

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return AuthScreen(
        onLoginSuccess: (user) => setState(() => _user = user),
      );
    }

    return DashboardScreen(user: _user!);
  }
}

class AuthScreen extends StatefulWidget {
  final void Function(AuthUser user) onLoginSuccess;

  const AuthScreen({super.key, required this.onLoginSuccess});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _loading = false;

  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  String? _registrationOtp;

  String _role = 'analyst';

  void _openForgotPassword() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()));
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Please fill in all required fields.');
      return;
    }

    if (!_isLogin && _fullNameCtrl.text.trim().isEmpty) {
      _showError('Please enter your full name.');
      return;
    }

    if (!_isLogin && (_mobileCtrl.text.trim().isEmpty || _otpCtrl.text.trim().isEmpty)) {
      _showError('Send and enter the mobile OTP before creating your account.');
      return;
    }

    if (!_isLogin && password != _confirmCtrl.text) {
      _showError('Passwords do not match.');
      return;
    }

    if (!_isLogin && password.length < 6) {
      _showError('Password must be at least 6 characters.');
      return;
    }

    setState(() => _loading = true);

    try {
      final user = _isLogin
          ? await AuthService.login(email: email, password: password)
          : await AuthService.register(
              username: _fullNameCtrl.text.trim(),
              email: email,
              password: password,
              role: _role,
              mobile: _mobileCtrl.text.trim(),
              otp: _otpCtrl.text.trim(),
            );

      if (!mounted) return;
      
      if (_isLogin) {
        _showSuccess('✓ Login successful! Welcome ${user.username}');
      } else {
        _showSuccess('✓ Account created! You are now logged in.');
      }
      
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        widget.onLoginSuccess(user);
      }
    } catch (e) {
      if (!mounted) return;
      String errorMsg = e.toString().replaceFirst('Exception: ', '');
      _showError(errorMsg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFF4560),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF00E396),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _mobileCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLogin = _isLogin;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A0F1E), Color(0xFF101A2D)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: 420,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00D4FF), Color(0xFF1A2340)],
                          ),
                          border: Border.all(color: const Color(0xFF00D4FF), width: 1),
                        ),
                        child: const Center(
                          child: Text('🛡', style: TextStyle(fontSize: 20)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                          ),
                          children: [
                            TextSpan(text: 'Sentinel', style: TextStyle(color: Color(0xFFE8EDF5))),
                            TextSpan(text: 'FD', style: TextStyle(color: Color(0xFF00D4FF))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Fraud Detection Intelligence Platform',
                    style: TextStyle(color: Color(0xFF6B7A99), fontSize: 13),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141B2D),
                      border: Border.all(color: const Color(0xFF1E2D4A)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isLogin ? 'Sign in' : 'Create account',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFE8EDF5),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isLogin
                              ? 'Access the intelligence console'
                              : 'Join your organisation\'s fraud unit',
                          style: const TextStyle(
                            color: Color(0xFF6B7A99),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 22),
                        if (!isLogin) ...[
                          _Field(
                            label: 'FULL NAME',
                            hintText: 'Dhruvil Bhatt',
                            icon: Icons.person_outline_rounded,
                            controller: _fullNameCtrl,
                          ),
                          const SizedBox(height: 16),
                          _Field(label: 'MOBILE NUMBER', hintText: '+91 9876543210', icon: Icons.phone_outlined, controller: _mobileCtrl, keyboardType: TextInputType.phone),
                          const SizedBox(height: 8),
                          TextButton(onPressed: () async {
                            try {
                              final otp = await AuthService.requestRegistrationOtp(_mobileCtrl.text.trim());
                              if (mounted) setState(() => _registrationOtp = otp);
                              if (mounted) _showSuccess('OTP sent. Development OTP: $otp');
                            } catch (error) { if (mounted) _showError(error.toString().replaceFirst('Exception: ', '')); }
                          }, child: const Text('Send mobile OTP')),
                          if (_registrationOtp != null) _Field(label: 'MOBILE OTP', hintText: '6-digit OTP', icon: Icons.verified_user_outlined, controller: _otpCtrl, keyboardType: TextInputType.number),
                          const SizedBox(height: 16),
                        ],
                        _Field(
                          label: 'WORK EMAIL',
                          hintText: 'you@organisation.com',
                          icon: Icons.email_outlined,
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        _Field(
                          label: 'PASSWORD',
                          hintText: 'Min. 6 characters',
                          icon: Icons.lock_outline_rounded,
                          controller: _passwordCtrl,
                          obscureText: true,
                        ),
                        if (!isLogin) ...[
                          const SizedBox(height: 16),
                          _Field(
                            label: 'CONFIRM PASSWORD',
                            hintText: 'Repeat password',
                            icon: Icons.lock_outline_rounded,
                            controller: _confirmCtrl,
                            obscureText: true,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'ROLE',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7A99),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: ['admin', 'analyst', 'viewer']
                                .map(
                                  (role) => Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: ChoiceChip(
                                        label: Text(role[0].toUpperCase() + role.substring(1)),
                                        selected: _role == role,
                                        onSelected: (_) => setState(() => _role = role),
                                        selectedColor: const Color(0xFF00D4FF),
                                        backgroundColor: const Color(0xFF0F1628),
                                        labelStyle: TextStyle(
                                          color: _role == role ? const Color(0xFF0A0F1E) : const Color(0xFFE8EDF5),
                                          fontWeight: FontWeight.w700,
                                        ),
                                        side: BorderSide(
                                          color: _role == role ? const Color(0xFF00D4FF) : const Color(0xFF1E2D4A),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _loading ? null : _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF00D4FF),
                              foregroundColor: const Color(0xFF0A0F1E),
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(isLogin ? 'Sign in' : 'Create account'),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const SizedBox.shrink(),
                        const SizedBox(height: 18),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _openForgotPassword,
                            child: const Text(
                              'Forgot password?',
                              style: TextStyle(color: Color(0xFF00D4FF)),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00D4FF).withAlpha((255 * 0.08).round()),
                            border: Border.all(color: const Color(0xFF00D4FF).withAlpha((255 * 0.2).round())),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.lock_outline_rounded, color: Color(0xFF00D4FF), size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Secured with end-to-end encryption',
                                style: TextStyle(color: Color(0xFF6B7A99), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Center(
                          child: TextButton(
                            onPressed: () => setState(() => _isLogin = !isLogin),
                            child: Text(
                              isLogin ? 'New analyst? Request access' : 'Already registered? Sign in',
                              style: const TextStyle(color: Color(0xFF00D4FF)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String hintText;
  final IconData icon;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType keyboardType;

  const _Field({
    required this.label,
    required this.hintText,
    required this.icon,
    required this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF6B7A99),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: const TextStyle(color: Color(0xFFE8EDF5)),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Color(0xFF6B7A99)),
            prefixIcon: Icon(icon, color: const Color(0xFF6B7A99), size: 18),
            filled: true,
            fillColor: const Color(0xFF0F1628),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF1E2D4A)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF1E2D4A)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF00D4FF)),
            ),
          ),
        ),
      ],
    );
  }
}

class DashboardScreen extends StatefulWidget {
  final AuthUser user;

  const DashboardScreen({super.key, required this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedTab = 0;
  String _recentFilter = 'All';
  bool _loading = true;
  String _error = '';
  Map<String, dynamic> _summary = {
    'totals': {'users': 0, 'transactions': 0, 'alerts': 0, 'fraud_rate': 0.0},
    'users': <Map<String, dynamic>>[],
    'transactions': <Map<String, dynamic>>[],
    'history': <Map<String, dynamic>>[],
  };

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    try {
      final data = await AuthService.getAdminSummary();
      if (!mounted) return;
      setState(() {
        _summary = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  List<String> get _tabs {
    if (widget.user.role == 'admin') {
      return ['Overview', 'Users', 'Transactions', 'History'];
    }
    return ['Overview', 'Transactions', 'History'];
  }

  List<Map<String, dynamic>> get _recentRows {
    final transactions = (_summary['transactions'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    final transactionById = {
      for (final transaction in transactions) transaction['id'].toString(): transaction,
    };
    final history = (_summary['history'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map));
    return history.map((item) {
      final transaction = transactionById[item['transaction_id'].toString()];
      return {
        ...item,
        'amount': item['amount'] ?? transaction?['amount'] ?? 0,
        'created_at': item['created_at'] ?? transaction?['created_at'],
      };
    }).where((item) => _recentFilter == 'All' || item['prediction'].toString().toUpperCase() == _recentFilter.toUpperCase()).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.user.role.toLowerCase() == 'admin';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      drawer: _DashboardDrawer(user: widget.user, onScanCompleted: _loadSummary),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101A2D),
        foregroundColor: const Color(0xFFE8EDF5),
        title: const Text('SentinelFD Console'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              label: Text(widget.user.role.toUpperCase()),
              backgroundColor: const Color(0xFF00D4FF).withAlpha((255 * 0.12).round()),
              side: const BorderSide(color: Color(0xFF00D4FF)),
              labelStyle: const TextStyle(color: Color(0xFF00D4FF), fontWeight: FontWeight.w700),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const AuthGate()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Logout'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFFF4560),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (MediaQuery.sizeOf(context).width >= 1050)
              SizedBox(width: 220, child: _DashboardRail(user: widget.user, onScanCompleted: _loadSummary)),
            Expanded(
              child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error.isNotEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _error,
                        style: const TextStyle(color: Color(0xFFFF4560)),
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(20),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        Text(
                          isAdmin ? 'Intelligence Dashboard' : 'Threat overview',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFE8EDF5),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Wednesday, 02 September 2026 - Live monitoring',
                          style: const TextStyle(color: Color(0xFF6B7A99), fontSize: 12),
                        ),
                        const SizedBox(height: 18),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: List.generate(_tabs.length, (index) {
                              final selected = _selectedTab == index;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(_tabs[index]),
                                  selected: selected,
                                  onSelected: (_) => setState(() => _selectedTab = index),
                                  selectedColor: const Color(0xFF00D4FF),
                                  backgroundColor: const Color(0xFF101A2D),
                                  labelStyle: TextStyle(
                                    color: selected ? const Color(0xFF0A0F1E) : const Color(0xFFE8EDF5),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 22),
                        if (_selectedTab == 0) ...[
                          LayoutBuilder(
                            builder: (context, constraints) => GridView.count(
                            shrinkWrap: true,
                            crossAxisCount: constraints.maxWidth >= 900 ? 4 : 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: constraints.maxWidth >= 900 ? 2.35 : 1.7,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              _MetricCard(
                                title: 'TOTAL USERS',
                                value: _summary['totals']['users'].toString(),
                                accent: const Color(0xFF00D4FF),
                              ),
                              _MetricCard(
                                title: 'TOTAL SCANNED',
                                value: '${_summary['totals']['transactions']}',
                                accent: const Color(0xFF00E396),
                              ),
                              _MetricCard(
                                title: 'FRAUD DETECTED',
                                value: '${_summary['totals']['alerts']}',
                                accent: const Color(0xFFFF4560),
                              ),
                              _MetricCard(
                                title: 'AVG FRAUD RATE',
                                value: '${_summary['totals']['fraud_rate']}%',
                                accent: const Color(0xFFFFB800),
                              ),
                            ],
                          )),
                          const SizedBox(height: 24),
                          _ProfileBanner(user: widget.user, summary: _summary),
                          const SizedBox(height: 24),
                          _Panel(
                            title: 'Recent Transactions',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  children: ['All', 'Fraud', 'Legitimate'].map((filter) => ChoiceChip(
                                    label: Text(filter),
                                    selected: _recentFilter == filter,
                                    onSelected: (_) => setState(() => _recentFilter = filter),
                                    selectedColor: const Color(0xFF00D4FF),
                                    backgroundColor: const Color(0xFF141B2D),
                                    side: const BorderSide(color: Color(0xFF1E2D4A)),
                                    labelStyle: TextStyle(color: _recentFilter == filter ? const Color(0xFF0A0F1E) : const Color(0xFF6B7A99), fontWeight: FontWeight.w700),
                                  )).toList(),
                                ),
                                const SizedBox(height: 16),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    headingRowHeight: 36,
                                    dataRowMinHeight: 52,
                                    dataRowMaxHeight: 60,
                                    columnSpacing: 34,
                                    headingTextStyle: const TextStyle(color: Color(0xFF6B7A99), fontSize: 12, fontWeight: FontWeight.w700),
                                    dataTextStyle: const TextStyle(color: Color(0xFFE8EDF5), fontSize: 12),
                                    columns: const [
                                      DataColumn(label: Text('Transaction ID')),
                                      DataColumn(label: Text('Amount')),
                                      DataColumn(label: Text('Verdict')),
                                      DataColumn(label: Text('Score')),
                                      DataColumn(label: Text('Votes')),
                                      DataColumn(label: Text('Time')),
                                    ],
                                    rows: _recentRows.take(10).map((item) {
                                      final fraud = item['prediction'].toString().toUpperCase() == 'FRAUD';
                                      final color = fraud ? const Color(0xFFFF4560) : const Color(0xFF00E396);
                                      final score = (item['fraud_score'] as num).toDouble();
                                      return DataRow(cells: [
                                        DataCell(Text('TXN${item['transaction_id']}', style: const TextStyle(color: Color(0xFF00D4FF), fontWeight: FontWeight.w700))),
                                        DataCell(Text('\$${(item['amount'] as num).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700))),
                                        DataCell(Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: color.withAlpha(25), border: Border.all(color: color.withAlpha(100)), borderRadius: BorderRadius.circular(5)), child: Text(item['prediction'].toString(), style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11)))),
                                        DataCell(Row(children: [SizedBox(width: 70, child: LinearProgressIndicator(value: score, minHeight: 5, color: color, backgroundColor: const Color(0xFF26324D), borderRadius: BorderRadius.circular(4))), const SizedBox(width: 8), Text(score.toStringAsFixed(2))])),
                                        DataCell(Text('${item['votes']}/3')),
                                        DataCell(Text(item['created_at']?.toString().replaceFirst('T', ' ') ?? 'n/a')),
                                      ]);
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (isAdmin && _selectedTab == 1) ...[
                          _Panel(
                            title: 'User management',
                            child: Column(
                              children: (_summary['users'] as List).map((user) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F1628),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              user['username'],
                                              style: const TextStyle(
                                                color: Color(0xFFE8EDF5),
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            Text(
                                              user['email'],
                                              style: const TextStyle(color: Color(0xFF6B7A99), fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: user['role'] == 'admin'
                                              ? const Color(0xFF00D4FF).withAlpha((255 * 0.12).round())
                                              : const Color(0xFF00E396).withAlpha((255 * 0.12).round()),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          user['role'].toString().toUpperCase(),
                                          style: TextStyle(
                                            color: user['role'] == 'admin'
                                                ? const Color(0xFF00D4FF)
                                                : const Color(0xFF00E396),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                      IconButton(tooltip: 'Edit user', icon: const Icon(Icons.edit_outlined, color: Color(0xFF00D4FF), size: 19), onPressed: () => _editUser(user)),
                                      IconButton(tooltip: 'Remove user', icon: const Icon(Icons.delete_outline, color: Color(0xFFFF4560), size: 19), onPressed: () => _removeUser(user['id'] as int)),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                        if ((_selectedTab == 2 && isAdmin) || (_selectedTab == 1 && !isAdmin)) ...[
                          _Panel(
                            title: 'Transaction records',
                            child: Column(
                              children: (_summary['transactions'] as List).map((txn) {
                                final amount = (txn['amount'] as num).toStringAsFixed(2);
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F1628),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Txn #${txn['id']} • ${txn['username'] ?? 'system'}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Color(0xFFE8EDF5),
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            Text(
                                              '${txn['source']} • ${txn['created_at'] ?? 'n/a'}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(color: Color(0xFF6B7A99), fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '\$$amount',
                                            style: const TextStyle(
                                              color: Color(0xFF00D4FF),
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          TextButton(
                                            onPressed: () => _showTransactionDetails(context, txn),
                                            child: const Text('View'),
                                          ),
                                          IconButton(tooltip: 'Edit transaction', icon: const Icon(Icons.edit_outlined, color: Color(0xFF00D4FF), size: 19), onPressed: () => _editTransaction(txn)),
                                          IconButton(tooltip: 'Remove transaction', icon: const Icon(Icons.delete_outline, color: Color(0xFFFF4560), size: 19), onPressed: () => _removeTransaction(txn['id'] as int)),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                        if ((_selectedTab == 3 && isAdmin) || (_selectedTab == 2 && !isAdmin)) ...[
                          _Panel(
                            title: 'History & audit trail',
                            child: Column(
                              children: (_summary['history'] as List).map((item) {
                                final fraud = item['prediction'].toString().toUpperCase() == 'FRAUD';
                                final statusColor = fraud ? const Color(0xFFFF4560) : const Color(0xFF00E396);
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F1628),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(width: 4, height: 48, decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(2))),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Txn #${item['transaction_id']} • ${item['prediction']}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Color(0xFFE8EDF5),
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            Text(
                                              'Score ${(item['fraud_score'] * 100).round()}% • Votes ${item['votes']}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(color: Color(0xFF6B7A99), fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: () => _downloadTransaction(item['transaction_id']),
                                        icon: const Icon(Icons.download_outlined, size: 16),
                                        label: const Text('Download'),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                        ],
                      ),
                    ),
                  ),
              ),
          ],
        ),
      ),
    );
  }

  void _showTransactionDetails(BuildContext context, Map<String, dynamic> transaction) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Transaction #${transaction['id']}'),
        content: Text('Amount: ${(transaction['amount'] as num).toStringAsFixed(2)}\nSource: ${transaction['source']}\nCreated: ${transaction['created_at'] ?? 'n/a'}'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  Future<void> _downloadTransaction(dynamic id) async {
    final uri = Uri.parse('${AuthService.baseUrl}/api/transactions/$id/download');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to start the transaction download.')));
    }
  }

  Future<void> _removeUser(int id) async {
    try { await AuthService.deleteAdminUser(id); await _loadSummary(); } catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString()))); }
  }

  Future<void> _editUser(Map<String, dynamic> user) async {
    final name = TextEditingController(text: user['username'].toString());
    final email = TextEditingController(text: user['email'].toString());
    final changes = await showDialog<Map<String, dynamic>>(context: context, builder: (_) => AlertDialog(
      title: const Text('Edit user'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: name, decoration: const InputDecoration(labelText: 'Username')), TextField(controller: email, decoration: const InputDecoration(labelText: 'Email'))]),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, {'username': name.text.trim(), 'email': email.text.trim()}), child: const Text('Save'))],
    ));
    name.dispose();
    email.dispose();
    if (changes == null) return;
    try { await AuthService.updateAdminUser(user['id'] as int, changes); await _loadSummary(); } catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString()))); }
  }

  Future<void> _editTransaction(Map<String, dynamic> transaction) async {
    final amount = TextEditingController(text: transaction['amount'].toString());
    final source = TextEditingController(text: transaction['source'].toString());
    final changes = await showDialog<Map<String, dynamic>>(context: context, builder: (_) => AlertDialog(
      title: const Text('Edit transaction'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount')), TextField(controller: source, decoration: const InputDecoration(labelText: 'Source'))]),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, {'amount': double.tryParse(amount.text), 'source': source.text.trim()}), child: const Text('Save'))],
    ));
    amount.dispose();
    source.dispose();
    if (changes == null || changes['amount'] == null) return;
    try { await AuthService.updateAdminTransaction(transaction['id'] as int, changes); await _loadSummary(); } catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString()))); }
  }

  Future<void> _removeTransaction(int id) async {
    try { await AuthService.deleteAdminTransaction(id); await _loadSummary(); } catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString()))); }
  }
}

class _ProfileBanner extends StatelessWidget {
  final AuthUser user;
  final Map<String, dynamic> summary;

  const _ProfileBanner({required this.user, required this.summary});

  @override
  Widget build(BuildContext context) {
    final totals = summary['totals'] as Map<String, dynamic>;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: const Color(0xFF141B2D), border: Border.all(color: const Color(0xFF1E2D4A)), borderRadius: BorderRadius.circular(12)),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 16,
        spacing: 24,
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            CircleAvatar(radius: 30, backgroundColor: const Color(0xFF00D4FF), child: Text(user.username.isEmpty ? '?' : user.username[0].toUpperCase(), style: const TextStyle(color: Color(0xFF0A0F1E), fontSize: 22, fontWeight: FontWeight.w900))),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Text(user.username, style: const TextStyle(color: Color(0xFFE8EDF5), fontSize: 17, fontWeight: FontWeight.w700)), const SizedBox(width: 10), _ProfileBadge(user.role.toUpperCase(), const Color(0xFF00D4FF)), const SizedBox(width: 6), _ProfileBadge('ACTIVE', const Color(0xFF00E396))]),
              const SizedBox(height: 5),
              Text(user.email, style: const TextStyle(color: Color(0xFF6B7A99), fontSize: 12)),
            ]),
          ]),
          Row(mainAxisSize: MainAxisSize.min, children: [
            _ProfileStat('${totals['transactions']}', 'Scans run'),
            const SizedBox(width: 24),
            _ProfileStat('${totals['alerts']}', 'Fraud found'),
            const SizedBox(width: 24),
            _ProfileStat('${(summary['history'] as List).length}', 'Predictions'),
          ]),
        ],
      ),
    );
  }
}

class _ProfileBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _ProfileBadge(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withAlpha(26), border: Border.all(color: color.withAlpha(75)), borderRadius: BorderRadius.circular(4)), child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)));
}

class _ProfileStat extends StatelessWidget {
  final String value;
  final String label;
  const _ProfileStat(this.value, this.label);

  @override
  Widget build(BuildContext context) => Column(children: [Text(value, style: const TextStyle(color: Color(0xFF00D4FF), fontSize: 20, fontWeight: FontWeight.w800)), Text(label, style: const TextStyle(color: Color(0xFF6B7A99), fontSize: 11))]);
}

class _DashboardRail extends StatelessWidget {
  final AuthUser user;
  final VoidCallback onScanCompleted;

  const _DashboardRail({required this.user, required this.onScanCompleted});

  void _openScanner(BuildContext context, {int mode = 0}) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => PredictScreen(initialMode: mode, onScanCompleted: onScanCompleted)));
  }

  void _logout(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F1628),
        border: Border(right: BorderSide(color: Color(0xFF1E2D4A))),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Row(children: [
              Container(width: 38, height: 38, decoration: BoxDecoration(color: const Color(0xFF00D4FF).withAlpha(28), border: Border.all(color: const Color(0xFF00D4FF).withAlpha(80)), borderRadius: BorderRadius.circular(10)), child: const Center(child: Text('🛡', style: TextStyle(fontSize: 18)))),
              const SizedBox(width: 10),
              const Text('SentinelFD', style: TextStyle(color: Color(0xFFE8EDF5), fontSize: 16, fontWeight: FontWeight.w800)),
            ]),
          ),
          const Divider(color: Color(0xFF1E2D4A), height: 1),
          Padding(padding: const EdgeInsets.all(12), child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9), decoration: BoxDecoration(color: const Color(0xFF00E396).withAlpha(18), border: Border.all(color: const Color(0xFF00E396).withAlpha(50)), borderRadius: BorderRadius.circular(6)), child: const Row(children: [Icon(Icons.circle, color: Color(0xFF00E396), size: 8), SizedBox(width: 8), Text('SYSTEM OPERATIONAL', style: TextStyle(color: Color(0xFF00E396), fontSize: 11, fontWeight: FontWeight.w700))]))),
          _railItem(Icons.dashboard_outlined, 'Dashboard', true, () {}),
          _railItem(Icons.search_rounded, 'Scan', false, () => _openScanner(context)),
          _railItem(Icons.folder_outlined, 'Batch Upload', false, () => _openScanner(context, mode: 2)),
          _railItem(Icons.person_outline_rounded, 'My Profile', false, () {}),
          const Spacer(),
          Padding(padding: const EdgeInsets.all(12), child: Column(children: [
            Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: const Color(0xFF141B2D), borderRadius: BorderRadius.circular(8)), child: Row(children: [CircleAvatar(radius: 16, backgroundColor: const Color(0xFF00D4FF), child: Text(user.username.isEmpty ? '?' : user.username[0].toUpperCase(), style: const TextStyle(color: Color(0xFF0A0F1E), fontWeight: FontWeight.w800))), const SizedBox(width: 9), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(user.username, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFE8EDF5), fontSize: 12, fontWeight: FontWeight.w600)), Text(user.role, style: const TextStyle(color: Color(0xFF6B7A99), fontSize: 11))]))])),
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => _logout(context), icon: const Icon(Icons.logout_rounded, size: 16), label: const Text('Sign out'), style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFFF4560), side: const BorderSide(color: Color(0x55FF4560)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))))),
          ])),
        ],
      ),
    );
  }

  Widget _railItem(IconData icon, String label, bool selected, VoidCallback onTap) => Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1), child: ListTile(leading: Icon(icon, color: selected ? const Color(0xFF00D4FF) : const Color(0xFF6B7A99), size: 19), title: Text(label, style: TextStyle(color: selected ? const Color(0xFF00D4FF) : const Color(0xFF6B7A99), fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.w400)), tileColor: selected ? const Color(0xFF00D4FF).withAlpha(24) : null, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 10), onTap: onTap));
}

class _DashboardDrawer extends StatelessWidget {
  final AuthUser user;
  final VoidCallback onScanCompleted;

  const _DashboardDrawer({required this.user, required this.onScanCompleted});

  void _logout(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF0F1628),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: const Color(0xFF00D4FF).withAlpha(30),
                      border: Border.all(color: const Color(0xFF00D4FF).withAlpha(70)),
                    ),
                    child: const Center(child: Text('🛡', style: TextStyle(fontSize: 17))),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'SentinelFD',
                    style: TextStyle(color: Color(0xFFE8EDF5), fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFF1E2D4A), height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E396).withAlpha(18),
                  border: Border.all(color: const Color(0xFF00E396).withAlpha(55)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.circle, color: Color(0xFF00E396), size: 8),
                    SizedBox(width: 8),
                    Text('SYSTEM OPERATIONAL', style: TextStyle(color: Color(0xFF00E396), fontSize: 11, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined, color: Color(0xFF00D4FF)),
              title: const Text('Dashboard', style: TextStyle(color: Color(0xFF00D4FF), fontSize: 13, fontWeight: FontWeight.w600)),
              tileColor: const Color(0xFF00D4FF).withAlpha(18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.search_rounded, color: Color(0xFF6B7A99)),
              title: const Text('Scan transaction', style: TextStyle(color: Color(0xFF6B7A99), fontSize: 13)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => PredictScreen(onScanCompleted: onScanCompleted)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file_outlined, color: Color(0xFF6B7A99)),
              title: const Text('Batch upload', style: TextStyle(color: Color(0xFF6B7A99), fontSize: 13)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => PredictScreen(initialMode: 2, onScanCompleted: onScanCompleted)));
              },
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFF141B2D), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: const Color(0xFF00D4FF),
                          child: Text(user.username.isEmpty ? '?' : user.username[0].toUpperCase(), style: const TextStyle(color: Color(0xFF0A0F1E), fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.username, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFE8EDF5), fontSize: 12, fontWeight: FontWeight.w600)),
                              Text(user.role, style: const TextStyle(color: Color(0xFF6B7A99), fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _logout(context),
                      icon: const Icon(Icons.logout_rounded, size: 16),
                      label: const Text('Sign out'),
                      style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFFF4560), side: const BorderSide(color: Color(0x55FF4560)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final Widget child;

  const _Panel({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF141B2D),
        border: Border.all(color: const Color(0xFF1E2D4A)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFE8EDF5)),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final Color accent;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF141B2D),
        border: Border.all(color: const Color(0xFF1E2D4A)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(width: 4, height: double.infinity, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
          Text(
            title,
            style: const TextStyle(color: Color(0xFF6B7A99), fontSize: 12, fontWeight: FontWeight.w700),
          ),
          Text(
            value,
            style: TextStyle(color: accent, fontSize: 26, fontWeight: FontWeight.w800),
          ),
            ],
          )),
        ],
      ),
    );
  }
}