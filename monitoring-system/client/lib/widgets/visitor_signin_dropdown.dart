import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/visitor_service.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import 'form_field.dart';
import 'submit_button.dart';

/// Header trigger + dropdown panel for visitor sign-in: a QR code (to fill
/// the form on a phone) and the same short form inline, for visitors at a
/// kiosk with a keyboard handy. Lives in [KioskHeader.trailing].
class VisitorSignInDropdown extends StatefulWidget {
  const VisitorSignInDropdown({super.key});

  @override
  State<VisitorSignInDropdown> createState() => _VisitorSignInDropdownState();
}

class _VisitorSignInDropdownState extends State<VisitorSignInDropdown> {
  final _link = LayerLink();
  OverlayEntry? _entry;

  void _toggle() => _entry == null ? _open() : _close();

  void _open() {
    final overlay = Overlay.of(context);
    _entry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _close,
            ),
          ),
          CompositedTransformFollower(
            link: _link,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomRight,
            followerAnchor: Alignment.topRight,
            offset: const Offset(0, 10),
            child: Material(
              color: Colors.transparent,
              child: _VisitorPanel(onClose: _close),
            ),
          ),
        ],
      ),
    );
    overlay.insert(_entry!);
    setState(() {});
  }

  void _close() {
    _entry?.remove();
    _entry = null;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _entry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final open = _entry != null;
    return CompositedTransformTarget(
      link: _link,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _toggle,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(open ? 0.22 : 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.how_to_reg, size: 16, color: Colors.white),
                const SizedBox(width: 6),
                const Text(
                  'Visitor Sign-In',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 18,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VisitorPanel extends StatefulWidget {
  final VoidCallback onClose;
  const _VisitorPanel({required this.onClose});

  @override
  State<_VisitorPanel> createState() => _VisitorPanelState();
}

class _VisitorPanelState extends State<_VisitorPanel> {
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
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400, maxHeight: 620),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Visitor Sign-In',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: widget.onClose,
                      borderRadius: BorderRadius.circular(14),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close, size: 18, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Please check in at reception.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                ),
                const SizedBox(height: 16),
                _buildQrRow(),
                const SizedBox(height: 18),
                const _OrDivider(),
                const SizedBox(height: 16),

                if (_error != null) _banner(_error!, isError: true),
                if (_success != null) _banner(_success!, isError: false),
                if (_error != null || _success != null) const SizedBox(height: 14),

                AppFormField(
                  label: 'FULL NAME',
                  hint: 'Jane Doe',
                  controller: _nameCtrl,
                  validator: (v) => Validators.validateMinLength(v, 2, 'Name'),
                ),
                const SizedBox(height: 12),
                AppFormField(
                  label: 'COMPANY / ORGANISATION (OPTIONAL)',
                  hint: 'Acme Ltd',
                  controller: _companyCtrl,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _pickerTile(
                        label: 'VISIT DATE',
                        value: DateFormat('EEE, d MMM').format(_visitDate),
                        icon: Icons.calendar_today,
                        onTap: _pickDate,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _pickerTile(
                        label: 'TIME IN',
                        value: _timeIn.format(context),
                        icon: Icons.schedule,
                        onTap: _pickTime,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AppFormField(
                  label: 'REASON FOR VISIT',
                  hint: 'Meeting with the Permanent Secretary',
                  controller: _reasonCtrl,
                  validator: (v) => Validators.validateMinLength(v, 3, 'Reason'),
                ),
                const SizedBox(height: 12),
                AppFormField(
                  label: 'ADDITIONAL DETAILS (OPTIONAL)',
                  hint: 'Anything else reception should know...',
                  controller: _descCtrl,
                  maxLines: 2,
                ),
                const SizedBox(height: 18),
                SubmitButton(
                  label: 'Sign In',
                  icon: Icons.how_to_reg,
                  loading: _loading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQrRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: QrImageView(
            data: AppConstants.visitorFormUrl,
            version: QrVersions.auto,
            size: 84,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Prefer your phone?',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Scan this code to open the sign-in form on your own device.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
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
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textFaint,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(icon, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _banner(String text, {required bool isError}) {
    final color = isError ? AppColors.danger : AppColors.success;
    final fg = isError ? AppColors.dangerText : AppColors.successText;
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Row(
        children: [
          Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: fg, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: fg, fontSize: 12.5))),
        ],
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            'OR FILL IN BELOW',
            style: TextStyle(
              color: AppColors.textFaint,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ),
        Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }
}
