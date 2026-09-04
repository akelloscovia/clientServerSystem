import 'package:flutter/material.dart';
import '../../models/submission.dart';
import '../../models/user.dart';
import '../../screens/submission_status_screen.dart';
import '../../services/submission_service.dart';
import 'dash_ui.dart';

/// Case queue for staff — review, re-status, reply and (admin) assign
/// submissions. Lifted from the old StaffDashboardScreen body.
class CasesSection extends StatefulWidget {
  final bool isAdmin;
  final Listenable? refreshSignal;
  const CasesSection({super.key, required this.isAdmin, this.refreshSignal});

  @override
  State<CasesSection> createState() => _CasesSectionState();
}

class _CasesSectionState extends State<CasesSection> {
  final _service = SubmissionService();
  List<Submission> _submissions = [];
  List<User> _secretaries = [];
  bool _loading = true;
  String? _error;
  String _status = '';

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
      final submissions = await _service.getStaffSubmissions(
          status: _status.isEmpty ? null : _status);
      final secretaries =
          widget.isAdmin ? await _service.getSecretaries() : <User>[];
      if (!mounted) return;
      setState(() {
        _submissions = submissions;
        _secretaries = secretaries;
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

  Future<void> _updateStatus(Submission s, String value) async {
    try {
      await _service.updateStatus(s.id, value);
      await _load();
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _reply(Submission s) async {
    final controller = TextEditingController();
    final message = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Dash.card,
        title: Text('Reply to case #${s.id}',
            style: const TextStyle(color: Dash.ink)),
        content: TextField(
          controller: controller,
          maxLines: 5,
          style: const TextStyle(color: Dash.ink),
          decoration: Dash.input('Response', hint: 'Write feedback...'),
        ),
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
      await _service.addResponse(s.id, message);
      _toast('Response sent.');
      await _load();
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _assign(Submission s) async {
    if (_secretaries.isEmpty) {
      _toast('No active secretaries available.');
      return;
    }
    int? selected;
    final notes = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setD) => AlertDialog(
          backgroundColor: Dash.card,
          title: Text('Assign case #${s.id}',
              style: const TextStyle(color: Dash.ink)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<int>(
              initialValue: selected,
              dropdownColor: Dash.field,
              style: const TextStyle(color: Dash.ink),
              decoration: Dash.input('Secretary'),
              items: _secretaries
                  .map((u) =>
                      DropdownMenuItem(value: u.id, child: Text(u.name)))
                  .toList(),
              onChanged: (v) => setD(() => selected = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notes,
              style: const TextStyle(color: Dash.ink),
              decoration: Dash.input('Instructions (optional)'),
            ),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed:
                    selected == null ? null : () => Navigator.pop(context, true),
                child: const Text('Assign')),
          ],
        ),
      ),
    );
    if (confirmed != true || selected == null) {
      notes.dispose();
      return;
    }
    try {
      await _service.assignSubmission(s.id, selected!, notes: notes.text.trim());
      _toast('Case assigned.');
      await _load();
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      notes.dispose();
    }
  }

  static const _statusItems = [
    DropdownMenuItem(value: '', child: Text('All statuses')),
    DropdownMenuItem(value: 'pending', child: Text('Pending')),
    DropdownMenuItem(value: 'under_review', child: Text('Under review')),
    DropdownMenuItem(value: 'assigned', child: Text('Assigned')),
    DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
    DropdownMenuItem(value: 'closed', child: Text('Closed')),
  ];

  @override
  Widget build(BuildContext context) {
    return SectionState(
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
          padding: const EdgeInsets.all(16),
          children: [
            SectionHeader('Cases',
                count: '${_submissions.length}',
                action: DropdownButton<String>(
                  value: _status,
                  dropdownColor: Dash.field,
                  style: const TextStyle(color: Dash.ink, fontSize: 13),
                  underline: const SizedBox.shrink(),
                  items: _statusItems,
                  onChanged: (v) {
                    setState(() => _status = v ?? '');
                    _load();
                  },
                )),
            if (_submissions.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                    child: Text('No cases match this filter.',
                        style: TextStyle(color: Dash.faint))),
              ),
            ..._submissions.map(_buildCard),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Submission s) {
    final color = Dash.caseStatus(s.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: Dash.cardBox,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text('#${s.id}  ${s.title}',
                style: const TextStyle(
                    color: Dash.ink, fontWeight: FontWeight.w700)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(99)),
            child: Text(s.priority.toUpperCase(),
                style: TextStyle(
                    color: color, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 8),
        Text(s.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Dash.dim, fontSize: 13)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          DropdownButton<String>(
            value: s.status,
            dropdownColor: Dash.field,
            style: const TextStyle(color: Dash.ink, fontSize: 13),
            underline: const SizedBox.shrink(),
            items: const [
              DropdownMenuItem(value: 'pending', child: Text('Pending')),
              DropdownMenuItem(
                  value: 'under_review', child: Text('Under review')),
              DropdownMenuItem(value: 'assigned', child: Text('Assigned')),
              DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
              DropdownMenuItem(value: 'closed', child: Text('Closed')),
            ],
            onChanged: (v) {
              if (v != null && v != s.status) _updateStatus(s, v);
            },
          ),
          OutlinedButton.icon(
              onPressed: () => _reply(s),
              icon: const Icon(Icons.reply, size: 16),
              label: const Text('Reply')),
          if (widget.isAdmin)
            OutlinedButton.icon(
                onPressed: () => _assign(s),
                icon: const Icon(Icons.person_add, size: 16),
                label: const Text('Assign')),
          TextButton.icon(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          SubmissionStatusScreen(submissionId: s.id))),
              icon: const Icon(Icons.visibility, size: 16),
              label: const Text('View')),
        ]),
      ]),
    );
  }
}
