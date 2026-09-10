import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/validators.dart';
import '../widgets/form_field.dart';
import '../widgets/submit_button.dart';
import 'home_screen.dart';
import 'main_shell.dart';

/// Client entry point — email only, no password. Staff still sign in
/// through [LoginScreen]; this is the low-friction path for regular users.
class ClientAccessScreen extends StatefulWidget {
  const ClientAccessScreen({super.key});

  @override
  State<ClientAccessScreen> createState() => _ClientAccessScreenState();
}

class _ClientAccessScreenState extends State<ClientAccessScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  final _auth = AuthService();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _auth.loginByEmail(_emailCtrl.text, name: _nameCtrl.text);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F6),
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3b82f6), Color(0xFF8b5cf6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3b82f6).withOpacity(0.35),
                            blurRadius: 24,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: const Icon(Icons.person, size: 36, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Ministry of Planning and Investment',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Enter your email to continue — no password needed',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF64748b), fontSize: 14),
                    ),
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0x14000000)),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            if (_error != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0x1AEF4444),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border(
                                    left: BorderSide(
                                        color: const Color(0xFFef4444), width: 4),
                                  ),
                                ),
                                child: Text(_error!,
                                    style: const TextStyle(
                                        color: Color(0xFFDC2626), fontSize: 13)),
                              ),
                              const SizedBox(height: 16),
                            ],
                            AppFormField(
                              label: 'FULL NAME',
                              hint: 'John Doe',
                              controller: _nameCtrl,
                              validator: (v) =>
                                  Validators.validateRequired(v, 'Name'),
                            ),
                            const SizedBox(height: 16),
                            AppFormField(
                              label: 'EMAIL ADDRESS',
                              hint: 'you@example.com',
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              validator: Validators.validateEmail,
                            ),
                            const SizedBox(height: 24),
                            SubmitButton(
                              label: 'Continue',
                              icon: Icons.arrow_forward,
                              loading: _loading,
                              onPressed: _submit,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: SafeArea(
              child: _buildBackButton(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      ),
      borderRadius: BorderRadius.circular(99),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0x14000000)),
        ),
        child: const Icon(Icons.arrow_back_ios_new,
            size: 16, color: Color(0xFF475569)),
      ),
    );
  }
}
