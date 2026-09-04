import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/program.dart';
import '../../services/program_service.dart';
import 'dash_ui.dart';

/// Admin + secretary: add / edit / delete programmes and set their venue
/// and time. Backed by `/api/programs` (create/edit/delete = staff).
class ProgramManager extends StatefulWidget {
  final Listenable? refreshSignal;
  const ProgramManager({super.key, this.refreshSignal});

  @override
  State<ProgramManager> createState() => _ProgramManagerState();
}

class _ProgramManagerState extends State<ProgramManager> {
  static const _days = [
    'daily', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday',
    'saturday', 'sunday'
  ];

  final _service = ProgramService();
  List<Program> _programs = [];
  bool _loading = true;
  String? _error;

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
      final programs = await _service.list(includeInactive: true);
      programs.sort((a, b) {
        final d = _days.indexOf(a.day).compareTo(_days.indexOf(b.day));
        return d != 0 ? d : a.startMinutes.compareTo(b.startMinutes);
      });
      if (!mounted) return;
      setState(() {
        _programs = programs;
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

  String _fmt(String hhmm) {
    final p = hhmm.split(':');
    final dt = DateTime(2000, 1, 1, int.tryParse(p[0]) ?? 0,
        p.length > 1 ? int.tryParse(p[1]) ?? 0 : 0);
    return DateFormat('h:mma').format(dt).toLowerCase();
  }

  Future<void> _openEditor([Program? existing]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _ProgramEditor(existing: existing, days: _days),
    );
    if (saved == true) {
      _toast(existing == null ? 'Programme added.' : 'Programme updated.');
      await _load();
    }
  }

  Future<void> _delete(Program p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Dash.card,
        title: const Text('Delete programme?',
            style: TextStyle(color: Dash.ink)),
        content: Text('"${p.title}" will be removed from the schedule.',
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
      await _service.delete(p.id);
      _toast('Programme deleted.');
      await _load();
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        backgroundColor: Dash.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add programme',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: SectionState(
        loading: _loading,
        error: _error,
        empty: _programs.isEmpty,
        emptyText: 'No programmes yet. Tap "Add programme".',
        onRetry: _load,
        child: RefreshIndicator(
          color: Dash.primary,
          backgroundColor: Dash.card,
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              SectionHeader('Programmes', count: '${_programs.length}'),
              ..._groupByDay(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _groupByDay() {
    final widgets = <Widget>[];
    String? currentDay;
    for (final p in _programs) {
      if (p.day != currentDay) {
        currentDay = p.day;
        widgets.add(Padding(
          padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
          child: Text(p.day[0].toUpperCase() + p.day.substring(1),
              style: const TextStyle(
                  color: Dash.dim,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8)),
        ));
      }
      widgets.add(_row(p));
    }
    return widgets;
  }

  Widget _row(Program p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: Dash.cardBox,
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text('${_fmt(p.startTime)}\n${_fmt(p.endTime)}',
                style: const TextStyle(
                    color: Dash.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(p.title,
                          style: const TextStyle(
                              color: Dash.ink, fontWeight: FontWeight.w700)),
                    ),
                    if (!p.isActive) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                            color: Dash.field,
                            borderRadius: BorderRadius.circular(4)),
                        child: const Text('HIDDEN',
                            style:
                                TextStyle(color: Dash.faint, fontSize: 9)),
                      ),
                    ],
                  ],
                ),
                if ((p.location ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(children: [
                      const Icon(Icons.location_on,
                          size: 12, color: Dash.faint),
                      const SizedBox(width: 3),
                      Text(p.location!,
                          style: const TextStyle(
                              color: Dash.faint, fontSize: 12)),
                    ]),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 18, color: Dash.dim),
            onPressed: () => _openEditor(p),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Dash.danger),
            onPressed: () => _delete(p),
          ),
        ],
      ),
    );
  }
}

class _ProgramEditor extends StatefulWidget {
  final Program? existing;
  final List<String> days;
  const _ProgramEditor({this.existing, required this.days});

  @override
  State<_ProgramEditor> createState() => _ProgramEditorState();
}

class _ProgramEditorState extends State<_ProgramEditor> {
  final _service = ProgramService();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _desc;
  late final TextEditingController _location;
  late String _day;
  late TimeOfDay _start;
  late TimeOfDay _end;
  late bool _active;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _desc = TextEditingController(text: e?.description ?? '');
    _location = TextEditingController(text: e?.location ?? '');
    _day = e?.day ?? 'daily';
    _start = _parse(e?.startTime ?? '09:00');
    _end = _parse(e?.endTime ?? '10:00');
    _active = e?.isActive ?? true;
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _location.dispose();
    super.dispose();
  }

  TimeOfDay _parse(String hhmm) {
    final p = hhmm.split(':');
    return TimeOfDay(
        hour: int.tryParse(p[0]) ?? 0,
        minute: p.length > 1 ? int.tryParse(p[1]) ?? 0 : 0);
  }

  String _hhmm(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pick(bool isStart) async {
    final picked = await showTimePicker(
        context: context, initialTime: isStart ? _start : _end);
    if (picked != null) {
      setState(() => isStart ? _start = picked : _end = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_end.hour * 60 + _end.minute <= _start.hour * 60 + _start.minute) {
      setState(() => _error = 'End time must be after the start time.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final body = {
      'title': _title.text.trim(),
      'description': _desc.text.trim(),
      'day': _day,
      'start_time': _hhmm(_start),
      'end_time': _hhmm(_end),
      'location': _location.text.trim(),
      'is_active': _active,
    };
    try {
      if (widget.existing == null) {
        await _service.create(body);
      } else {
        await _service.update(widget.existing!.id, body);
      }
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
      title: Text(widget.existing == null ? 'Add programme' : 'Edit programme',
          style: const TextStyle(color: Dash.ink)),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
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
                  controller: _title,
                  style: const TextStyle(color: Dash.ink),
                  decoration: Dash.input('Title'),
                  validator: (v) =>
                      (v == null || v.trim().length < 2) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _desc,
                  style: const TextStyle(color: Dash.ink),
                  maxLines: 2,
                  decoration: Dash.input('Description (optional)'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _day,
                  dropdownColor: Dash.field,
                  style: const TextStyle(color: Dash.ink),
                  decoration: Dash.input('Day'),
                  items: widget.days
                      .map((d) => DropdownMenuItem(
                          value: d,
                          child: Text(d[0].toUpperCase() + d.substring(1))))
                      .toList(),
                  onChanged: (v) => setState(() => _day = v ?? 'daily'),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                      child: _timeField('Start time', _start, () => _pick(true))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _timeField('End time', _end, () => _pick(false))),
                ]),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _location,
                  style: const TextStyle(color: Dash.ink),
                  decoration: Dash.input('Venue / location'),
                ),
                const SizedBox(height: 4),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: Dash.primary,
                  title: const Text('Visible on the kiosk',
                      style: TextStyle(color: Dash.dim, fontSize: 14)),
                  value: _active,
                  onChanged: (v) => setState(() => _active = v),
                ),
              ],
            ),
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
              : const Text('Save'),
        ),
      ],
    );
  }

  Widget _timeField(String label, TimeOfDay value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: Dash.input(label),
        child: Text(value.format(context),
            style: const TextStyle(color: Dash.ink, fontSize: 14)),
      ),
    );
  }
}
