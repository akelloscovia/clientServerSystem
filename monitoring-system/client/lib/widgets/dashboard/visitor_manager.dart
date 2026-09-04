import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user.dart';
import '../../models/visitor.dart';
import '../../services/submission_service.dart';
import '../../services/visitor_service.dart';
import 'dash_ui.dart';

/// Staff view of the walk-in visitor sign-in log. Everyone can re-status and
/// reply; admins can also assign a secretary and delete entries.
class VisitorManager extends StatefulWidget {
  final bool isAdmin;
  final Listenable? refreshSignal;
  const VisitorManager({super.key, required this.isAdmin, this.refreshSignal});

  @override
  State<VisitorManager> createState() => _VisitorManagerState();
}

class _VisitorManagerState extends State<VisitorManager> {
  final _service = VisitorService();
  final _subs = SubmissionService();
  List<Visitor> _visitors = [];
  List<User> _secretaries = [];
  bool _loading = true;
  String? _error;
  String _filter = '';

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
      final visitors = await _service.list(status: _filter.isEmpty ? null : _filter);
      final secretaries =
          widget.isAdmin ? await _subs.getSecretaries() : <User>[];
      if (!mounted) return;
      setState(() {
        _visitors = visitors;
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

  Future<void> _setStatus(Visitor v, String status) async {
    try {
      await _service.updateStatus(v.id, status);
      await _load();
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _reply(Visitor v) async {
    final controller = TextEditingController();
    final message = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Dash.card,
        title: Text('Reply to ${v.name}', style: const TextStyle(color: Dash.ink)),
        content: TextField(
          controller: controller,
          maxLines: 4,
          style: const TextStyle(color: Dash.ink),
          decoration: Dash.input('Message'),
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
      await _service.reply(v.id, message);
      _toast('Reply added.');
      await _load();
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _assign(Visitor v) async {
    if (_secretaries.isEmpty) {
      _toast('No active secretaries available.');
      return;
    }
    int? selected = v.assignedTo;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setD) => AlertDialog(
          backgroundColor: Dash.card,
          title: Text('Assign ${v.name}',
              style: const TextStyle(color: Dash.ink)),
          content: DropdownButtonFormField<int>(
            initialValue: selected,
            dropdownColor: Dash.field,
            style: const TextStyle(color: Dash.ink),
            decoration: Dash.input('Secretary'),
            items: _secretaries
                .map((u) => DropdownMenuItem(value: u.id, child: Text(u.name)))
                .toList(),
            onChanged: (v) => setD(() => selected = v),
          ),
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
        ),
      ),
    );
    if (ok != true || selected == null) return;
    try {
      await _service.assign(v.id, selected!);
      _toast('Visitor assigned.');
      await _load();
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _delete(Visitor v) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Dash.card,
        title: const Text('Delete entry?', style: TextStyle(color: Dash.ink)),
        content: Text('${v.name}\'s sign-in will be permanently removed.',
            style: const TextStyle(color: Dash.dim)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Dash.danger),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.delete(v.id);
      _toast('Entry deleted.');
      await _load();
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  static const _filters = ['', 'pending', 'assigned', 'attended', 'closed'];

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
            SectionHeader('Visitor sign-ins', count: '${_visitors.length}'),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final f = _filters[i];
                  final active = _filter == f;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _filter = f);
                      _load();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: active
                            ? Dash.primary.withValues(alpha: 0.2)
                            : Dash.field,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                            color: active ? Dash.primary : Dash.line),
                      ),
                      child: Text(f.isEmpty ? 'All' : _cap(f),
                          style: TextStyle(
                              color: active ? Dash.primaryText : Dash.dim,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            if (_visitors.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                    child: Text('No visitors match this filter.',
                        style: TextStyle(color: Dash.faint))),
              ),
            ..._visitors.map(_card),
          ],
        ),
      ),
    );
  }

  String _cap(String s) => s[0].toUpperCase() + s.substring(1);

  Widget _card(Visitor v) {
    final color = Dash.visitorStatus(v.status);
    final when = [
      if ((v.visitDate ?? '').isNotEmpty) _prettyDate(v.visitDate!),
      if ((v.timeIn ?? '').isNotEmpty) v.timeIn!,
    ].join(' · ');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: Dash.cardBox,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(
              v.name + ((v.company ?? '').isNotEmpty ? '  ·  ${v.company}' : ''),
              style: const TextStyle(
                  color: Dash.ink, fontWeight: FontWeight.w700),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(99)),
            child: Text(v.status.toUpperCase(),
                style: TextStyle(
                    color: color, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        ]),
        if (when.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(when,
                style: const TextStyle(color: Dash.faint, fontSize: 12)),
          ),
        const SizedBox(height: 6),
        Text(v.reasonForVisit,
            style: const TextStyle(color: Dash.dim, fontSize: 13)),
        if ((v.description ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(v.description!,
                style: const TextStyle(color: Dash.faint, fontSize: 12)),
          ),
        if (v.assignee != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('Assigned to ${v.assignee}',
                style: const TextStyle(
                    color: Dash.primaryText, fontSize: 12)),
          ),
        for (final r in v.replies)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Dash.field, borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.responder ?? 'Staff',
                    style: const TextStyle(
                        color: Dash.dim,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(r.message,
                    style: const TextStyle(color: Dash.dim, fontSize: 12)),
              ],
            ),
          ),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          DropdownButton<String>(
            value: v.status,
            dropdownColor: Dash.field,
            style: const TextStyle(color: Dash.ink, fontSize: 13),
            underline: const SizedBox.shrink(),
            items: Visitor.statuses
                .map((s) =>
                    DropdownMenuItem(value: s, child: Text(_cap(s))))
                .toList(),
            onChanged: (s) {
              if (s != null && s != v.status) _setStatus(v, s);
            },
          ),
          OutlinedButton.icon(
              onPressed: () => _reply(v),
              icon: const Icon(Icons.reply, size: 16),
              label: const Text('Reply')),
          if (widget.isAdmin) ...[
            OutlinedButton.icon(
                onPressed: () => _assign(v),
                icon: const Icon(Icons.person_add, size: 16),
                label: const Text('Assign')),
            TextButton.icon(
                onPressed: () => _delete(v),
                icon: const Icon(Icons.delete_outline,
                    size: 16, color: Dash.danger),
                label: const Text('Delete',
                    style: TextStyle(color: Dash.danger))),
          ],
        ]),
      ]),
    );
  }

  String _prettyDate(String iso) {
    final dt = DateTime.tryParse(iso);
    return dt == null ? iso : DateFormat('EEE, d MMM').format(dt);
  }
}
