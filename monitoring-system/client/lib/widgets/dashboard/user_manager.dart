import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/submission_service.dart';
import 'dash_ui.dart';

/// Admin: list accounts, change roles, activate / deactivate, and create
/// new staff or client accounts.
class UserManager extends StatefulWidget {
  final Listenable? refreshSignal;
  const UserManager({super.key, this.refreshSignal});

  @override
  State<UserManager> createState() => _UserManagerState();
}

class _UserManagerState extends State<UserManager> {
  final _service = SubmissionService();
  List<User> _users = [];
  bool _loading = true;
  String? _error;
  String _roleFilter = '';

  @override
  void initState() {
    super.initState();
    _load();
    widget.refreshSignal?.addListener(_load);
  }

  @override
  void dispose() {
    widget.refreshSignal?.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final users = await _service.getUsers();
      if (!mounted) return;
      setState(() {
        _users = users;
        _error = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _setRole(User u, String role) async {
    try {
      await _service.updateUserRole(u.id, role);
      _toast('${u.name} is now ${_cap(role)}.');
      await _load();
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _toggleActive(User u) async {
    try {
      await _service.toggleUserActive(u.id);
      await _load();
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _addStaff() async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => const _AddStaffDialog(),
    );
    if (saved == true) {
      _toast('Account created.');
      await _load();
    }
  }

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    final filtered = _roleFilter.isEmpty
        ? _users
        : _users.where((u) => u.role == _roleFilter).toList();
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addStaff,
        backgroundColor: Dash.primary,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Add account',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: SectionState(
        loading: _loading,
        error: _error,
        empty: false,
        emptyText: '',
        onRetry: _load,
        child: RefreshIndicator(
          color: Dash.primary,
          backgroundColor: Dash.card,
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              SectionHeader('Accounts',
                  count: '${filtered.length}',
                  action: DropdownButton<String>(
                    value: _roleFilter,
                    dropdownColor: Dash.field,
                    style: const TextStyle(color: Dash.ink, fontSize: 13),
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(value: '', child: Text('All roles')),
                      DropdownMenuItem(value: 'admin', child: Text('Admins')),
                      DropdownMenuItem(
                          value: 'secretary', child: Text('Secretaries')),
                      DropdownMenuItem(value: 'user', child: Text('Clients')),
                    ],
                    onChanged: (v) => setState(() => _roleFilter = v ?? ''),
                  )),
              ...filtered.map(_row),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(User u) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: Dash.cardBox,
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Dash.primary.withValues(alpha: 0.2),
            child: Text(
                u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: Dash.primaryText, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(u.name,
                    style: const TextStyle(
                        color: Dash.ink, fontWeight: FontWeight.w700)),
                Text(u.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Dash.faint, fontSize: 12)),
                if (!u.isActive)
                  const Text('deactivated',
                      style: TextStyle(color: Dash.danger, fontSize: 11)),
              ],
            ),
          ),
          DropdownButton<String>(
            value: u.role,
            dropdownColor: Dash.field,
            style: const TextStyle(color: Dash.ink, fontSize: 13),
            underline: const SizedBox.shrink(),
            items: const [
              DropdownMenuItem(value: 'user', child: Text('Client')),
              DropdownMenuItem(value: 'secretary', child: Text('Secretary')),
              DropdownMenuItem(value: 'admin', child: Text('Admin')),
            ],
            onChanged: (v) {
              if (v != null && v != u.role) _setRole(u, v);
            },
          ),
          IconButton(
            tooltip: u.isActive ? 'Deactivate' : 'Activate',
            icon: Icon(
                u.isActive ? Icons.toggle_on : Icons.toggle_off,
                color: u.isActive ? Dash.ok : Dash.faint,
                size: 26),
            onPressed: () => _toggleActive(u),
          ),
        ],
      ),
    );
  }
}

class _AddStaffDialog extends StatefulWidget {
  const _AddStaffDialog();

  @override
  State<_AddStaffDialog> createState() => _AddStaffDialogState();
}

class _AddStaffDialogState extends State<_AddStaffDialog> {
  final _service = SubmissionService();
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String _role = 'secretary';
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _service.registerStaff(
          _name.text, _email.text, _password.text, _role);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Dash.card,
      title: const Text('Add account', style: TextStyle(color: Dash.ink)),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_error != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Dash.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_error!,
                      style: const TextStyle(
                          color: Color(0xFFfca5a5), fontSize: 13)),
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _name,
                style: const TextStyle(color: Dash.ink),
                decoration: Dash.input('Full name'),
                validator: (v) =>
                    (v == null || v.trim().length < 2) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                style: const TextStyle(color: Dash.ink),
                keyboardType: TextInputType.emailAddress,
                decoration: Dash.input('Email'),
                validator: (v) =>
                    (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                style: const TextStyle(color: Dash.ink),
                obscureText: true,
                decoration: Dash.input('Temporary password'),
                validator: (v) {
                  if (v == null || v.length < 8) return 'At least 8 characters';
                  if (!v.contains(RegExp(r'[A-Z]'))) return 'Needs an uppercase letter';
                  if (!v.contains(RegExp(r'[0-9]'))) return 'Needs a digit';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _role,
                dropdownColor: Dash.field,
                style: const TextStyle(color: Dash.ink),
                decoration: Dash.input('Role'),
                items: const [
                  DropdownMenuItem(value: 'secretary', child: Text('Secretary')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'user', child: Text('Client')),
                ],
                onChanged: (v) => setState(() => _role = v ?? 'secretary'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Create'),
        ),
      ],
    );
  }
}
