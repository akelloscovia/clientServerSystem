import 'package:flutter/material.dart';
import '../models/submission.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/submission_service.dart';
import 'login_screen.dart';
import 'submission_status_screen.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  final _service = SubmissionService();
  final _auth = AuthService();
  List<Submission> _submissions = [];
  List<User> _secretaries = [];
  List<User> _users = [];
  Map<String, dynamic>? _stats;
  bool _loading = true;
  String? _error;
  String _status = '';

  bool get isAdmin => _auth.currentUser?.role == 'admin';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final submissions = await _service.getStaffSubmissions(
          status: _status.isEmpty ? null : _status);
      List<User> secretaries = [];
      List<User> users = [];
      Map<String, dynamic>? stats;
      if (isAdmin) {
        secretaries = await _service.getSecretaries();
        users = await _service.getUsers();
        stats = await _service.getStats();
      }
      if (!mounted) return;
      setState(() {
        _submissions = submissions;
        _secretaries = secretaries;
        _users = users;
        _stats = stats;
      });
    } catch (e) {
      if (mounted)
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await _auth.logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  Future<void> _updateStatus(Submission submission, String value) async {
    try {
      await _service.updateStatus(submission.id, value);
      await _load();
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _reply(Submission submission) async {
    final controller = TextEditingController();
    final message = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reply to case #${submission.id}'),
        content: TextField(
            controller: controller,
            maxLines: 5,
            decoration: const InputDecoration(
                hintText: 'Write feedback or a response...')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Send')),
        ],
      ),
    );
    controller.dispose();
    if (message == null || message.isEmpty) return;
    try {
      await _service.addResponse(submission.id, message);
      _showMessage('Response sent.');
      await _load();
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _assign(Submission submission) async {
    if (_secretaries.isEmpty) {
      _showMessage('No active secretaries available.');
      return;
    }
    int? selected;
    final notes = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
                title: Text('Assign case #${submission.id}'),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  DropdownButtonFormField<int>(
                    value: selected,
                    decoration: const InputDecoration(labelText: 'Secretary'),
                    items: _secretaries
                        .map((user) => DropdownMenuItem(
                            value: user.id, child: Text(user.name)))
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => selected = value),
                  ),
                  TextField(
                      controller: notes,
                      decoration: const InputDecoration(
                          labelText: 'Instructions (optional)')),
                ]),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: selected == null
                          ? null
                          : () => Navigator.pop(context, true),
                      child: const Text('Assign')),
                ],
              )),
    );
    if (confirmed != true || selected == null) return;
    try {
      await _service.assignSubmission(submission.id, selected!,
          notes: notes.text.trim());
      _showMessage('Submission assigned.');
      await _load();
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      notes.dispose();
    }
  }

  Future<void> _showUsers() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manage users'),
        content: SizedBox(
            width: 420,
            child: ListView(
                shrinkWrap: true,
                children: _users
                    .map((user) => ListTile(
                          title: Text(user.name),
                          subtitle: Text('${user.email} - ${user.role}'),
                          trailing: Icon(
                              user.isActive ? Icons.check_circle : Icons.block,
                              color: user.isActive ? Colors.green : Colors.red),
                        ))
                    .toList())),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'))
        ],
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final role = _auth.currentUser?.role == 'admin'
        ? 'Admin Dashboard'
        : 'Secretary Workspace';
    return Scaffold(
      appBar: AppBar(title: Text(role), actions: [
        IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        IconButton(onPressed: _logout, icon: const Icon(Icons.logout))
      ]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(padding: const EdgeInsets.all(16), children: [
                    if (isAdmin) _buildAdminSummary(),
                    Row(children: [
                      const Text('Cases',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      DropdownButton<String>(
                          value: _status,
                          items: const [
                            DropdownMenuItem(
                                value: '', child: Text('All statuses')),
                            DropdownMenuItem(
                                value: 'pending', child: Text('Pending')),
                            DropdownMenuItem(
                                value: 'under_review',
                                child: Text('Under review')),
                            DropdownMenuItem(
                                value: 'assigned', child: Text('Assigned')),
                            DropdownMenuItem(
                                value: 'resolved', child: Text('Resolved')),
                            DropdownMenuItem(
                                value: 'closed', child: Text('Closed')),
                          ],
                          onChanged: (value) {
                            setState(() => _status = value ?? '');
                            _load();
                          }),
                    ]),
                    const SizedBox(height: 12),
                    if (_submissions.isEmpty)
                      const Padding(
                          padding: EdgeInsets.all(32),
                          child:
                              Center(child: Text('No submissions available.'))),
                    ..._submissions.map(_buildSubmissionCard),
                  ])),
    );
  }

  Widget _buildAdminSummary() {
    final overview = _stats?['overview'] as Map<String, dynamic>? ?? {};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        _metric('All cases', overview['total']),
        _metric('Pending', overview['pending']),
        _metric('Users', overview['total_users']),
        _metric('Secretaries', overview['secretaries']),
      ]),
      const SizedBox(height: 8),
      Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
              onPressed: _showUsers,
              icon: const Icon(Icons.manage_accounts),
              label: const Text('Manage users'))),
      const SizedBox(height: 12),
    ]);
  }

  Widget _metric(String label, dynamic value) => Expanded(
      child: Card(
          child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                Text('${value ?? 0}',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                Text(label, textAlign: TextAlign.center)
              ]))));

  Widget _buildSubmissionCard(Submission submission) {
    return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
            padding: const EdgeInsets.all(14),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                    child: Text('#${submission.id} ${submission.title}',
                        style: const TextStyle(fontWeight: FontWeight.bold))),
                Text(submission.priority.toUpperCase())
              ]),
              const SizedBox(height: 8),
              Text(submission.description,
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [
                DropdownButton<String>(
                    value: submission.status,
                    items: const [
                      DropdownMenuItem(
                          value: 'pending', child: Text('Pending')),
                      DropdownMenuItem(
                          value: 'under_review', child: Text('Under review')),
                      DropdownMenuItem(
                          value: 'assigned', child: Text('Assigned')),
                      DropdownMenuItem(
                          value: 'resolved', child: Text('Resolved')),
                      DropdownMenuItem(value: 'closed', child: Text('Closed')),
                    ],
                    onChanged: (value) {
                      if (value != null && value != submission.status)
                        _updateStatus(submission, value);
                    }),
                OutlinedButton.icon(
                    onPressed: () => _reply(submission),
                    icon: const Icon(Icons.reply),
                    label: const Text('Reply')),
                if (isAdmin)
                  OutlinedButton.icon(
                      onPressed: () => _assign(submission),
                      icon: const Icon(Icons.person_add),
                      label: const Text('Assign')),
                TextButton.icon(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => SubmissionStatusScreen(
                                submissionId: submission.id))),
                    icon: const Icon(Icons.visibility),
                    label: const Text('View')),
              ]),
            ])));
  }
}
