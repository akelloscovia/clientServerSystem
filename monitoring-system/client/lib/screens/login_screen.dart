import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/validators.dart';
import '../widgets/form_field.dart';
import '../widgets/submit_button.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  bool _loading     = false;
  bool _obscure     = true;
  bool _isRegister  = false;
  final _nameCtrl   = TextEditingController();
  String? _error;

  final _auth = AuthService();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      if (_isRegister) {
        await _auth.register(_nameCtrl.text, _emailCtrl.text, _passCtrl.text);
      } else {
        await _auth.login(_emailCtrl.text, _passCtrl.text);
      }
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
    _passCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0d14),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Logo
                Container(
                  width: 72, height: 72,
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
                        blurRadius: 24, spreadRadius: 2,
                      )
                    ],
                  ),
                  child: const Icon(Icons.bolt, size: 36, color: Colors.white),
                ),
                const SizedBox(height: 20),
                const Text('MonitorSys',
                  style: TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontSize: 28, fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isRegister ? 'Create your account' : 'Sign in to continue',
                  style: const TextStyle(color: Color(0xFF64748b), fontSize: 14),
                ),
                const SizedBox(height: 40),

                // Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0x12FFFFFF)),
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
                                left: BorderSide(color: const Color(0xFFef4444), width: 4),
                              ),
                            ),
                            child: Text(_error!,
                              style: const TextStyle(color: Color(0xFFfca5a5), fontSize: 13)),
                          ),
                          const SizedBox(height: 16),
                        ],

                        if (_isRegister) ...[
                          AppFormField(
                            label: 'FULL NAME',
                            hint: 'John Doe',
                            controller: _nameCtrl,
                            validator: (v) => Validators.validateRequired(v, 'Name'),
                          ),
                          const SizedBox(height: 16),
                        ],

                        AppFormField(
                          label: 'EMAIL ADDRESS',
                          hint: 'you@example.com',
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          validator: Validators.validateEmail,
                        ),
                        const SizedBox(height: 16),
                        AppFormField(
                          label: 'PASSWORD',
                          hint: '••••••••',
                          controller: _passCtrl,
                          obscureText: _obscure,
                          validator: _isRegister
                              ? Validators.validatePassword
                              : (v) => Validators.validateRequired(v, 'Password'),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure ? Icons.visibility_off : Icons.visibility,
                              color: const Color(0xFF64748b), size: 20,
                            ),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        const SizedBox(height: 24),

                        SubmitButton(
                          label: _isRegister ? 'Create Account' : 'Sign In',
                          icon: _isRegister ? Icons.person_add : Icons.lock_open,
                          loading: _loading,
                          onPressed: _submit,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => setState(() { _isRegister = !_isRegister; _error = null; }),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 14, color: Color(0xFF64748b)),
                      children: [
                        TextSpan(text: _isRegister
                            ? "Already have an account? "
                            : "Don't have an account? "),
                        TextSpan(
                          text: _isRegister ? 'Sign In' : 'Register',
                          style: const TextStyle(
                            color: Color(0xFF3b82f6),
                            fontWeight: FontWeight.w600,
                          ),
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
    );
  }
}
