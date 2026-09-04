import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/validators.dart';
import '../widgets/form_field.dart';
import '../widgets/submit_button.dart';
import 'main_shell.dart';

/// Staff-only sign in (admin / secretary). Regular clients use
/// [ClientAccessScreen] instead — email only, no password.
///
/// When [embedded] is true the screen renders without its own Scaffold or
/// back button so it can sit inside the [MainShell] Admin Portal tab; on a
/// successful sign in it calls [onSignedIn] instead of navigating.
class LoginScreen extends StatefulWidget {
  final bool embedded;
  final VoidCallback? onSignedIn;

  const LoginScreen({super.key, this.embedded = false, this.onSignedIn});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String _selectedRole = 'admin';
  String? _error;

  final _auth = AuthService();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await _auth.login(_emailCtrl.text, _passCtrl.text);
      if (user.role != _selectedRole) {
        await _auth.logout();
        throw Exception(
          'This account is registered as ${user.role}. Select the ${user.role} login button.',
        );
      }
      if (!mounted) return;
      if (widget.embedded) {
        widget.onSignedIn?.call();
      } else {
        // Sign in leads to the home page; the Admin Portal tab inside the
        // shell shows the staff dashboard now that a session exists.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainShell()),
          (route) => false,
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: _buildFormColumn(),
        ),
      ),
    );

    if (widget.embedded) {
      return Container(color: const Color(0xFF0a0d14), child: content);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0a0d14),
      body: Stack(
        children: [
          SafeArea(child: content),
          Positioned(
            top: 12,
            left: 12,
            child: SafeArea(child: _buildBackButton(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildFormColumn() {
    return Column(
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
                  '${_roleLabel(_selectedRole)} sign in',
                  style:
                      const TextStyle(color: Color(0xFF64748b), fontSize: 14),
                ),
                const SizedBox(height: 40),

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
                  ],
                ),
                const SizedBox(height: 20),

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
                          validator: (v) =>
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
                          label: 'Sign In',
                          icon: Icons.lock_open,
                          loading: _loading,
                          onPressed: _submit,
                        ),
                      ],
                    ),
                  ),
                ),
      ],
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
      default:
        return 'Secretary workspace';
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
