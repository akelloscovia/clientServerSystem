import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/validators.dart';
import '../widgets/form_field.dart';
import '../widgets/submit_button.dart';
import 'home_screen.dart';
import 'staff_dashboard_screen.dart';
import 'kiosk_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  bool _isRegister = false;
  String _selectedRole = 'user';
  final _nameCtrl = TextEditingController();
  String? _error;

  final _auth = AuthService();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_isRegister) {
        await _auth.register(_nameCtrl.text, _emailCtrl.text, _passCtrl.text);
      } else {
        final user = await _auth.login(_emailCtrl.text, _passCtrl.text);
        if (user.role != _selectedRole) {
          await _auth.logout();
          throw Exception(
            'This account is registered as ${user.role}. Select the ${user.role} login button.',
          );
        }
      }
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => _auth.currentUser?.role == 'user'
                ? const HomeScreen()
                : const StaffDashboardScreen(),
          ),
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
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                // Logo
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
                  child: const Icon(Icons.bolt, size: 36, color: Colors.white),
                ),
                const SizedBox(height: 20),
                const Text(
                  'MonitorSys',
                  style: TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isRegister
                      ? 'Create a client account'
                      : '${_roleLabel(_selectedRole)} sign in',
                  style:
                      const TextStyle(color: Color(0xFF64748b), fontSize: 14),
                ),
                const SizedBox(height: 40),

                if (!_isRegister) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('SELECT PORTAL',
                        style: TextStyle(
                          color: Color(0xFF64748b),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        )),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _roleButton('admin', 'Admin', Icons.admin_panel_settings),
                      const SizedBox(width: 8),
                      _roleButton(
                          'secretary', 'Secretary', Icons.assignment_ind),
                      const SizedBox(width: 8),
                      _roleButton('user', 'Client', Icons.person),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

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
                                left: BorderSide(
                                    color: const Color(0xFFef4444), width: 4),
                              ),
                            ),
                            child: Text(_error!,
                                style: const TextStyle(
                                    color: Color(0xFFfca5a5), fontSize: 13)),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (_isRegister) ...[
                          AppFormField(
                            label: 'FULL NAME',
                            hint: 'John Doe',
                            controller: _nameCtrl,
                            validator: (v) =>
                                Validators.validateRequired(v, 'Name'),
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
                              : (v) =>
                                  Validators.validateRequired(v, 'Password'),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: const Color(0xFF64748b),
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SubmitButton(
                          label: _isRegister ? 'Create Account' : 'Sign In',
                          icon:
                              _isRegister ? Icons.person_add : Icons.lock_open,
                          loading: _loading,
                          onPressed: _submit,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => setState(() {
                    _isRegister = !_isRegister;
                    _selectedRole = 'user';
                    _error = null;
                  }),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF64748b)),
                      children: [
                        TextSpan(
                            text: _isRegister
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
        MaterialPageRoute(builder: (_) => const KioskHomeScreen()),
        (route) => false,
      ),
      borderRadius: BorderRadius.circular(99),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0x12FFFFFF)),
        ),
        child: const Icon(Icons.arrow_back_ios_new,
            size: 16, color: Color(0xFF94a3b8)),
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Admin portal';
      case 'secretary':
        return 'Secretary workspace';
      default:
        return 'Client portal';
    }
  }

  Widget _roleButton(String role, String label, IconData icon) {
    final selected = _selectedRole == role;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() {
          _selectedRole = role;
          _error = null;
        }),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? const Color(0x263b82f6) : const Color(0xFF0d1422),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color:
                  selected ? const Color(0xFF3b82f6) : const Color(0x1AFFFFFF),
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 20,
                  color: selected
                      ? const Color(0xFF60a5fa)
                      : const Color(0xFF64748b)),
              const SizedBox(height: 5),
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected
                        ? const Color(0xFFdbeafe)
                        : const Color(0xFF94a3b8),
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
