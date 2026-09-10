import 'package:flutter/material.dart';
import '../../models/channel.dart';
import '../../services/channel_service.dart';
import 'dash_ui.dart';

/// Admin: manage the reception TV channel list (`/api/channels`).
class ChannelManager extends StatefulWidget {
  final Listenable? refreshSignal;
  const ChannelManager({super.key, this.refreshSignal});

  @override
  State<ChannelManager> createState() => _ChannelManagerState();
}

class _ChannelManagerState extends State<ChannelManager> {
  final _service = ChannelService();
  List<Channel> _channels = [];
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
      final channels = await _service.list(includeInactive: true);
      if (!mounted) return;
      setState(() {
        _channels = channels;
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

  Future<void> _openEditor([Channel? existing]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _ChannelEditor(existing: existing),
    );
    if (saved == true) {
      _toast(existing == null ? 'Channel added.' : 'Channel updated.');
      await _load();
    }
  }

  Future<void> _delete(Channel c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Dash.card,
        title: const Text('Delete channel?', style: TextStyle(color: Dash.ink)),
        content: Text('"${c.name}" will be removed from the kiosk.',
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
      await _service.delete(c.id);
      _toast('Channel deleted.');
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
        heroTag: 'fab_channel_manager',
        onPressed: () => _openEditor(),
        backgroundColor: Dash.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add channel',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: SectionState(
        loading: _loading,
        error: _error,
        empty: _channels.isEmpty,
        emptyText: 'No channels yet. Tap "Add channel".',
        onRetry: _load,
        child: RefreshIndicator(
          color: Dash.primary,
          backgroundColor: Dash.card,
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              SectionHeader('TV Channels', count: '${_channels.length}'),
              ..._channels.map(_row),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(Channel c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: Dash.cardBox,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: Dash.field, borderRadius: BorderRadius.circular(8)),
            child: Text('${c.sortOrder}',
                style: const TextStyle(color: Dash.dim, fontSize: 13)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(
                    child: Text(c.name,
                        style: const TextStyle(
                            color: Dash.ink, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                        color: Dash.field,
                        borderRadius: BorderRadius.circular(4)),
                    child: Text(c.streamType.toUpperCase(),
                        style: const TextStyle(
                            color: Dash.primaryText, fontSize: 9)),
                  ),
                  if (!c.isActive) ...[
                    const SizedBox(width: 6),
                    const Text('hidden',
                        style: TextStyle(color: Dash.faint, fontSize: 10)),
                  ],
                ]),
                Text(c.streamUrl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Dash.faint, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 18, color: Dash.dim),
            onPressed: () => _openEditor(c),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Dash.danger),
            onPressed: () => _delete(c),
          ),
        ],
      ),
    );
  }
}

class _ChannelEditor extends StatefulWidget {
  final Channel? existing;
  const _ChannelEditor({this.existing});

  @override
  State<_ChannelEditor> createState() => _ChannelEditorState();
}

class _ChannelEditorState extends State<_ChannelEditor> {
  static const _types = ['hls', 'youtube', 'mp4', 'other'];

  final _service = ChannelService();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _url;
  late final TextEditingController _order;
  late String _type;
  late bool _active;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _url = TextEditingController(text: e?.streamUrl ?? '');
    _order = TextEditingController(text: '${e?.sortOrder ?? 0}');
    _type = e?.streamType ?? 'hls';
    _active = e?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    _order.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final body = {
      'name': _name.text.trim(),
      'stream_url': _url.text.trim(),
      'stream_type': _type,
      'sort_order': int.tryParse(_order.text.trim()) ?? 0,
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
      title: Text(widget.existing == null ? 'Add channel' : 'Edit channel',
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
                            color: Color(0xFFDC2626), fontSize: 13)),
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: _name,
                  style: const TextStyle(color: Dash.ink),
                  decoration: Dash.input('Channel name'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _url,
                  style: const TextStyle(color: Dash.ink),
                  decoration: Dash.input('Stream / page URL',
                      hint: 'https://...'),
                  validator: (v) => (v == null || v.trim().length < 5)
                      ? 'Enter a valid URL'
                      : null,
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _type,
                      dropdownColor: Dash.field,
                      style: const TextStyle(color: Dash.ink),
                      decoration: Dash.input('Type'),
                      items: _types
                          .map((t) => DropdownMenuItem(
                              value: t, child: Text(t.toUpperCase())))
                          .toList(),
                      onChanged: (v) => setState(() => _type = v ?? 'hls'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 96,
                    child: TextFormField(
                      controller: _order,
                      style: const TextStyle(color: Dash.ink),
                      keyboardType: TextInputType.number,
                      decoration: Dash.input('Order'),
                    ),
                  ),
                ]),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: Dash.primary,
                  title: const Text('Show on the kiosk',
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
}
