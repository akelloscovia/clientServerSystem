import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/visitor_service.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import 'form_field.dart';
import 'submit_button.dart';

/// In-app visitor sign-in form for the reception kiosk. Posts straight to
/// the public `/api/visitors/` endpoint — no login required. A QR code is
/// shown alongside so visitors can also fill the form in on their phone.
class VisitorSignInView extends StatefulWidget {
  const VisitorSignInView({super.key});

  @override
  State<VisitorSignInView> createState() => _VisitorSignInViewState();
}

class _VisitorSignInViewState extends State<VisitorSignInView> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  DateTime _visitDate = DateTime.now();
  TimeOfDay _timeIn = TimeOfDay.now();

  bool _loading = false;
  String? _error;
  String? _success;

  final _service = VisitorService();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _companyCtrl.dispose();
    _reasonCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _visitDate,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _visitDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _timeIn);
    if (picked != null) setState(() => _timeIn = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });
    try {
      final message = await _service.createVisitor(
        name: _nameCtrl.text,
        company: _companyCtrl.text,
        visitDate: DateFormat('yyyy-MM-dd').format(_visitDate),
        timeIn:
            '${_timeIn.hour.toString().padLeft(2, '0')}:${_timeIn.minute.toString().padLeft(2, '0')}',
        reasonForVisit: _reasonCtrl.text,
        description: _descCtrl.text,
      );
      if (!mounted) return;
      setState(() {
        _success = message;
        _nameCtrl.clear();
        _companyCtrl.clear();
        _reasonCtrl.clear();
        _descCtrl.clear();
        _visitDate = DateTime.now();
        _timeIn = TimeOfDay.now();
      });
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 780;
        final form = _buildForm();
        final qr = _buildQrPanel();
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: form),
                        const SizedBox(width: 24),
                        Expanded(flex: 2, child: qr),
                      ],
                    )
                  : Column(children: [form, const SizedBox(height: 20), qr]),
            ),
          ),
        );
      },
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x12FFFFFF)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Visitor Sign-In',
                style: TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Please check in at reception.',
                style: TextStyle(color: Color(0xFF64748b), fontSize: 13)),
            const SizedBox(height: 20),

            if (_error != null) _banner(_error!, isError: true),
            if (_success != null) _banner(_success!, isError: false),
            if (_error != null || _success != null) const SizedBox(height: 16),

            AppFormField(
              label: 'FULL NAME',
              hint: 'Jane Doe',
              controller: _nameCtrl,
              validator: (v) => Validators.validateMinLength(v, 2, 'Name'),
            ),
            const SizedBox(height: 14),
            AppFormField(
              label: 'COMPANY / ORGANISATION (OPTIONAL)',
              hint: 'Acme Ltd',
              controller: _companyCtrl,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                    child: _pickerTile(
                        label: 'VISIT DATE',
                        value: DateFormat('EEE, d MMM yyyy').format(_visitDate),
                        icon: Icons.calendar_today,
                        onTap: _pickDate)),
                const SizedBox(width: 12),
                Expanded(
                    child: _pickerTile(
                        label: 'TIME IN',
                        value: _timeIn.format(context),
                        icon: Icons.schedule,
                        onTap: _pickTime)),
              ],
            ),
            const SizedBox(height: 14),
            AppFormField(
              label: 'REASON FOR VISIT',
              hint: 'Meeting with the Permanent Secretary',
              controller: _reasonCtrl,
              validator: (v) => Validators.validateMinLength(v, 3, 'Reason'),
            ),
            const SizedBox(height: 14),
            AppFormField(
              label: 'ADDITIONAL DETAILS (OPTIONAL)',
              hint: 'Anything else reception should know...',
              controller: _descCtrl,
              maxLines: 3,
            ),
            const SizedBox(height: 22),
            SubmitButton(
              label: 'Sign In',
              icon: Icons.how_to_reg,
              loading: _loading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _pickerTile({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF94a3b8),
                letterSpacing: 0.6)),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF1a2235),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x12FFFFFF)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 15, color: const Color(0xFF64748b)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(value,
                      style: const TextStyle(
                          color: Color(0xFFF1F5F9), fontSize: 14)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _banner(String text, {required bool isError}) {
    final color = isError ? const Color(0xFFef4444) : const Color(0xFF10b981);
    final fg = isError ? const Color(0xFFfca5a5) : const Color(0xFF6ee7b7);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Row(
        children: [
          Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
              color: fg, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text, style: TextStyle(color: fg, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildQrPanel() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x12FFFFFF)),
      ),
      child: Column(
        children: [
          const Text('Prefer your phone?',
              style: TextStyle(
                  color: Color(0xFFF1F5F9),
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Scan to open this form on your device',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748b), fontSize: 12)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12)),
            child: QrImageView(
              data: AppConstants.visitorFormUrl,
              version: QrVersions.auto,
              size: 170,
            ),
          ),
        ],
      ),
    );
  }
}
