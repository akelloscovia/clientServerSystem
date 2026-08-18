import 'package:flutter/material.dart';
import '../services/submission_service.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../widgets/form_field.dart';
import '../widgets/submit_button.dart';

class SubmissionScreen extends StatefulWidget {
  const SubmissionScreen({super.key});

  @override
  State<SubmissionScreen> createState() => _SubmissionScreenState();
}

class _SubmissionScreenState extends State<SubmissionScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  String _category = 'other';
  String _priority = 'medium';
  bool _loading    = false;
  String? _error;
  String? _success;

  final _service = SubmissionService();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; _success = null; });
    try {
      await _service.createSubmission(
        title:       _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        category:    _category,
        priority:    _priority,
      );
      setState(() => _success = 'Submission created successfully!');
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChange,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
          style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600,
            color: Color(0xFF94a3b8), letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChange,
          dropdownColor: const Color(0xFF1a2235),
          style: const TextStyle(color: Color(0xFFF1F5F9), fontSize: 14),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            filled: true,
            fillColor: const Color(0xFF1a2235),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0x12FFFFFF)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0x12FFFFFF)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF3b82f6), width: 2),
            ),
          ),
          items: items.map((item) => DropdownMenuItem(
            value: item,
            child: Text(item[0].toUpperCase() + item.substring(1)),
          )).toList(),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0d14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0d1117),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF94a3b8), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('New Submission',
          style: TextStyle(color: Color(0xFFF1F5F9),
            fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF3b82f6).withOpacity(0.15),
                      const Color(0xFF8b5cf6).withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF3b82f6).withOpacity(0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF60a5fa), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Fill in the details below. Our team will review and respond to your case.',
                        style: TextStyle(color: Color(0xFF93c5fd), fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0x1AEF4444),
                    borderRadius: BorderRadius.circular(8),
                    border: Border(left: BorderSide(color: const Color(0xFFef4444), width: 4)),
                  ),
                  child: Text(_error!,
                    style: const TextStyle(color: Color(0xFFfca5a5), fontSize: 13)),
                ),
                const SizedBox(height: 16),
              ],

              if (_success != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0x1A10B981),
                    borderRadius: BorderRadius.circular(8),
                    border: Border(left: BorderSide(color: const Color(0xFF10b981), width: 4)),
                  ),
                  child: Text(_success!,
                    style: const TextStyle(color: Color(0xFF6ee7b7), fontSize: 13)),
                ),
                const SizedBox(height: 16),
              ],

              AppFormField(
                label: 'TITLE',
                hint: 'Brief title of your case',
                controller: _titleCtrl,
                validator: (v) => Validators.validateMinLength(v, 5, 'Title'),
              ),
              const SizedBox(height: 16),

              AppFormField(
                label: 'DESCRIPTION',
                hint: 'Describe your case in detail...',
                controller: _descCtrl,
                maxLines: 5,
                validator: (v) => Validators.validateMinLength(v, 10, 'Description'),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildDropdown(
                      'CATEGORY', _category,
                      AppConstants.categories,
                      (v) => setState(() => _category = v ?? 'other'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDropdown(
                      'PRIORITY', _priority,
                      AppConstants.priorities,
                      (v) => setState(() => _priority = v ?? 'medium'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              SubmitButton(
                label: 'Submit Case',
                icon: Icons.send,
                loading: _loading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
