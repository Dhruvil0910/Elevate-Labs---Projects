import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/prediction_result.dart';
import '../services/api_service.dart';
import 'result_screen.dart';

const _navy = Color(0xFF0A0F1E);
const _navyMid = Color(0xFF0F1628);
const _card = Color(0xFF141B2D);
const _border = Color(0xFF1E2D4A);
const _cyan = Color(0xFF00D4FF);
const _green = Color(0xFF00E396);
const _red = Color(0xFFFF4560);
const _muted = Color(0xFF6B7A99);

class PredictScreen extends StatefulWidget {
  final int initialMode;
  final VoidCallback? onScanCompleted;
  const PredictScreen({super.key, this.initialMode = 0, this.onScanCompleted});

  @override
  State<PredictScreen> createState() => _PredictScreenState();
}

class _PredictScreenState extends State<PredictScreen> {
  final _formKey = GlobalKey<FormState>();
  final _transactionId = TextEditingController();
  final _amount = TextEditingController();
  final _time = TextEditingController();
  final _dateTime = TextEditingController();
  final _merchantId = TextEditingController();
  final _merchantName = TextEditingController();
  final _text = TextEditingController();
  late int _mode;
  String _currency = 'USD';
  String _transactionType = 'purchase';
  String _merchantCategory = 'electronics';
  String _merchantCountry = 'US';
  bool _onlineMerchant = true;
  bool _loading = false;
  String? _fileName;
  File? _file;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _dateTime.text = _formatDateTime(DateTime.now());
  }

  String _formatDateTime(DateTime value) => '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  Future<void> _chooseDateTime() async {
    final date = await showDatePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2035), initialDate: DateTime.now());
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time != null) setState(() => _dateTime.text = _formatDateTime(DateTime(date.year, date.month, date.day, time.hour, time.minute)));
  }

  Future<void> _pickFile(List<String> extensions) async {
    final picked = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: extensions);
    if (picked.isEmpty || picked.single.path == null) return;
    setState(() {
      _file = File(picked.single.path!);
      _fileName = picked.single.name;
    });
  }

  Future<void> _submit() async {
    if (_mode == 0 && !_formKey.currentState!.validate()) return;
    if (_mode > 1 && _file == null) {
      _message('Choose a ${_mode == 2 ? 'CSV' : 'PDF'} file first.');
      return;
    }
    setState(() => _loading = true);
    try {
      late Map<String, dynamic> response;
      if (_mode == 0) {
        final date = DateTime.tryParse(_dateTime.text.replaceFirst(' ', 'T'));
        final metadata = {
          'transaction_id': _transactionId.text.trim(),
          'currency': _currency,
          'transaction_datetime': _dateTime.text.trim(),
          'transaction_hour': date?.hour ?? 0,
          'transaction_day_of_week': date?.weekday ?? DateTime.now().weekday,
          'is_weekend': (date?.weekday ?? 1) >= 6,
          'transaction_type': _transactionType,
          'merchant_id': _merchantId.text.trim(),
          'merchant_name': _merchantName.text.trim(),
          'merchant_category': _merchantCategory,
          'merchant_country': _merchantCountry,
          'is_online_merchant': _onlineMerchant,
        };
        response = await ApiService.predictSingle([double.parse(_time.text), ...List.filled(28, 0.0), double.parse(_amount.text)], metadata: metadata);
      } else if (_mode == 1) {
        final labeled = RegExp(r'time\s*[:=]\s*([\d.]+).*amount\s*[:=]\s*([\d.]+)', caseSensitive: false, dotAll: true).firstMatch(_text.text);
        final values = labeled != null
          ? [double.parse(labeled.group(1)!), ...List.filled(28, 0.0), double.parse(labeled.group(2)!)]
          : _text.text.split(RegExp(r'[\s,]+')).where((item) => item.isNotEmpty).map(double.parse).toList();
        if (values.length != 30) throw Exception('Text input must contain Time, 28 V features, and Amount (30 numbers).');
        response = await ApiService.predictSingle(values);
      } else if (_mode == 2) {
        response = await ApiService.predictBatch(_file!);
      } else if (_mode == 3) {
        response = await ApiService.predictPdf(_file!);
      } else {
        _message('Text input is available from the Text input tab.');
        return;
      }
      if (!mounted) return;
      widget.onScanCompleted?.call();
      if (_mode == 2) {
        _showBatchResults(response);
      } else {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ResultScreen(result: PredictionResult.fromJson(response))));
      }
    } catch (error) {
      _message(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showBatchResults(Map<String, dynamic> response) {
    final results = (response['results'] as List).cast<Map<String, dynamic>>();
    showModalBottomSheet<void>(context: context, isScrollControlled: true, backgroundColor: _card, builder: (_) => SafeArea(child: SizedBox(height: MediaQuery.sizeOf(context).height * .75, child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Batch Results', style: TextStyle(color: Color(0xFFE8EDF5), fontSize: 20, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text('${response['total']} scanned | ${response['fraud_count']} fraud detected', style: const TextStyle(color: _muted)),
      const SizedBox(height: 16),
      Expanded(child: ListView.builder(itemCount: results.length, itemBuilder: (_, index) { final item = results[index]; final fraud = item['is_fraud'] == true; return ListTile(leading: Icon(fraud ? Icons.warning_amber_rounded : Icons.check_circle, color: fraud ? _red : _green), title: Text('Transaction ${index + 1}', style: const TextStyle(color: Color(0xFFE8EDF5))), subtitle: Text('${item['prediction']} | ${(item['fraud_score'] * 100).toStringAsFixed(1)}%', style: const TextStyle(color: _muted))); })),
    ])))));
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), backgroundColor: _red));

  @override
  void dispose() {
    _transactionId.dispose();
    _amount.dispose();
    _time.dispose();
    _dateTime.dispose();
    _merchantId.dispose();
    _merchantName.dispose();
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const modes = ['Manual entry', 'Text input', 'CSV batch', 'PDF upload'];
    return Scaffold(backgroundColor: _navy, appBar: AppBar(title: const Text('Transaction Scanner'), backgroundColor: _navyMid), body: SingleChildScrollView(padding: const EdgeInsets.all(28), child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 760), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Transaction Scanner', style: TextStyle(color: Color(0xFFE8EDF5), fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      const Text('Submit a single credit card transaction for real-time fraud analysis', style: TextStyle(color: _muted, fontSize: 13)),
      const SizedBox(height: 24),
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: modes.asMap().entries.map((entry) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(entry.value), selected: _mode == entry.key, onSelected: (_) => setState(() => _mode = entry.key), selectedColor: _cyan, backgroundColor: _navyMid, side: const BorderSide(color: _border), labelStyle: TextStyle(color: _mode == entry.key ? _navy : _muted, fontSize: 12, fontWeight: FontWeight.w600)))).toList())),
      const SizedBox(height: 16),
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: _card, border: Border.all(color: _border), borderRadius: BorderRadius.circular(12)), child: _inputBody()),
    ])))));
  }

  Widget _inputBody() {
    if (_mode == 0) return _manualForm();
    if (_mode == 1) return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Paste 30 comma- or space-separated values: Time, V1-V28, Amount.', style: TextStyle(color: _muted, fontSize: 13)), const SizedBox(height: 12), TextField(controller: _text, maxLines: 6, style: const TextStyle(color: Color(0xFFE8EDF5)), decoration: _decoration('MODEL VALUES', '0, 0, 0, ... , 4820.50', null)), const SizedBox(height: 18), _submitButton('Analyse text')]);
    final pdf = _mode == 3;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(pdf ? 'Upload a PDF containing Amount and optional Time values.' : 'Upload a CSV with Time, V1-V28, and Amount columns.', style: const TextStyle(color: _muted, fontSize: 13)), const SizedBox(height: 18), OutlinedButton.icon(onPressed: () => _pickFile([pdf ? 'pdf' : 'csv']), icon: Icon(pdf ? Icons.picture_as_pdf_outlined : Icons.upload_file_outlined), label: Text(_fileName ?? 'Choose ${pdf ? 'PDF' : 'CSV'} file'), style: OutlinedButton.styleFrom(foregroundColor: _cyan, side: const BorderSide(color: _cyan), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)))), if (_fileName != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_fileName!, style: const TextStyle(color: _green, fontSize: 12))), const SizedBox(height: 20), _submitButton(pdf ? 'Analyse PDF' : 'Start batch scan')]);
  }

  Widget _manualForm() => Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Transaction details', style: TextStyle(color: _cyan, fontSize: 13, fontWeight: FontWeight.w600)),
    const SizedBox(height: 16),
    _field(_transactionId, 'TRANSACTION ID (OPTIONAL)', 'TXN20240901-A3F9', Icons.tag_outlined, required: false),
    const SizedBox(height: 14),
    _field(_amount, 'AMOUNT (USD)', '4820.50', Icons.credit_card_outlined, numeric: true),
    const SizedBox(height: 14),
    _field(_time, 'TIME (seconds since first transaction)', '86400', Icons.timer_outlined, numeric: true),
    const SizedBox(height: 14),
    _field(_dateTime, 'TRANSACTION DATETIME', '2024-09-01 02:34', Icons.schedule_outlined, readOnly: true, onTap: _chooseDateTime),
    const SizedBox(height: 14),
    Row(children: [Expanded(child: _dropdown('CURRENCY', _currency, ['USD', 'EUR', 'INR', 'GBP'], (value) => setState(() => _currency = value!))), const SizedBox(width: 12), Expanded(child: _dropdown('TRANSACTION TYPE', _transactionType, ['purchase', 'refund', 'withdrawal'], (value) => setState(() => _transactionType = value!)))]),
    const SizedBox(height: 24),
    const Text('Merchant details', style: TextStyle(color: _cyan, fontSize: 13, fontWeight: FontWeight.w600)),
    const SizedBox(height: 16),
    _field(_merchantId, 'MERCHANT ID', 'MERCH-00441', Icons.storefront_outlined),
    const SizedBox(height: 14),
    _field(_merchantName, 'MERCHANT NAME', 'Amazon or unknown_store', Icons.business_outlined),
    const SizedBox(height: 14),
    Row(children: [Expanded(child: _dropdown('MERCHANT CATEGORY', _merchantCategory, ['electronics', 'grocery', 'travel', 'luxury', 'other'], (value) => setState(() => _merchantCategory = value!))), const SizedBox(width: 12), Expanded(child: _dropdown('MERCHANT COUNTRY', _merchantCountry, ['US', 'IN', 'GB', 'NG', 'RO'], (value) => setState(() => _merchantCountry = value!)))]),
    SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('ONLINE MERCHANT', style: TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w700)), subtitle: const Text('Card-not-present transactions carry higher risk.', style: TextStyle(color: _muted, fontSize: 12)), value: _onlineMerchant, activeThumbColor: _cyan, onChanged: (value) => setState(() => _onlineMerchant = value)),
    const SizedBox(height: 12),
    _submitButton('Run fraud scan'),
  ]));

  Widget _field(TextEditingController controller, String label, String hint, IconData icon, {bool numeric = false, bool readOnly = false, bool required = true, VoidCallback? onTap}) => TextFormField(controller: controller, readOnly: readOnly, onTap: onTap, keyboardType: numeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text, style: const TextStyle(color: Color(0xFFE8EDF5), fontSize: 13), validator: required ? (value) => value == null || value.trim().isEmpty ? 'Required' : null : null, decoration: _decoration(label, hint, icon));

  Widget _dropdown(String label, String value, List<String> values, ValueChanged<String?> onChanged) => DropdownButtonFormField<String>(initialValue: value, dropdownColor: _card, style: const TextStyle(color: Color(0xFFE8EDF5), fontSize: 13), decoration: _decoration(label, '', null), items: values.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(), onChanged: onChanged);

  InputDecoration _decoration(String label, String hint, IconData? icon) => InputDecoration(labelText: label, hintText: hint, prefixIcon: icon == null ? null : Icon(icon, color: _muted, size: 18), labelStyle: const TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w700), hintStyle: const TextStyle(color: _muted, fontSize: 13), filled: true, fillColor: _navyMid, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _cyan)));

  Widget _submitButton(String text) => SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _loading ? null : _submit, icon: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.search_rounded, size: 18), label: Text(_loading ? 'Analysing...' : text), style: FilledButton.styleFrom(backgroundColor: _cyan, foregroundColor: _navy, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)))));
}
