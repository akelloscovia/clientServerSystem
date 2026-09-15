import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/visitor.dart';
import '../services/visitor_service.dart';
import '../utils/app_colors.dart';

/// The Minister's visitor queue: everyone still waiting to be seen (status
/// `pending` or `assigned`), with quick Allow In / Postpone actions. Sits
/// alongside [ProgramsView] as the other half of [KioskHomeView]'s
/// Reception/Minister toggle.
class VisitorQueueView extends StatefulWidget {
  const VisitorQueueView({super.key});

  @override
  State<VisitorQueueView> createState() => _VisitorQueueViewState();
}

class _VisitorQueueViewState extends State<VisitorQueueView> {
  final _service = VisitorService();
  List<Visitor> _visitors = [];
  bool _loading = true;
  String? _error;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(const Duration(seconds: 20), (_) => _load());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (_visitors.isEmpty && mounted) setState(() => _loading = true);
    try {
      final all = await _service.list();
      final waiting = all
          .where((v) => v.status == 'pending' || v.status == 'assigned')
          .toList()
        ..sort((a, b) => _arrivalTime(a).compareTo(_arrivalTime(b)));
      if (!mounted) return;
      setState(() {
        _visitors = waiting;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  /// When this visitor arrived, for first-come-first-served ordering. Prefers
  /// the visit date + time-in shown on their card (what a viewer reads as
  /// "when they came"); falls back to the sign-in record's creation time,
  /// and finally to the end of the queue so a visitor with no timestamp at
  /// all doesn't jump ahead of everyone else.
  DateTime _arrivalTime(Visitor v) {
    if ((v.visitDate ?? '').isNotEmpty && (v.timeIn ?? '').isNotEmpty) {
      final parsed = DateTime.tryParse('${v.visitDate}T${v.timeIn}:00');
      if (parsed != null) return parsed;
    }
    return DateTime.tryParse(v.createdAt ?? '') ?? DateTime(9999);
  }

  Future<void> _setStatus(Visitor v, String status) async {
    Navigator.of(context).pop();
    try {
      await _service.updateStatus(v.id, status);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p[0]).join().toUpperCase();
  }

  String _timeLabel(Visitor v) {
    if (v.timeIn == null || v.timeIn!.isEmpty) return '--';
    final parts = v.timeIn!.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return DateFormat('h:mma').format(DateTime(2000, 1, 1, h, m)).toLowerCase();
  }

  void _openDetail(Visitor v) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.14),
              foregroundColor: AppColors.primaryDark,
              child: Text(_initials(v.name),
                  style:
                      const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(v.name,
                  style:
                      const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Organization',
                  (v.company ?? '').isNotEmpty ? v.company! : 'Individual visitor'),
              _detailRow('Reason', v.reasonForVisit),
              if ((v.description ?? '').isNotEmpty)
                _detailRow('Details', v.description!),
              _detailRow('Time in', _timeLabel(v)),
              _detailRow('Status',
                  v.assignee != null ? '${v.status} · ${v.assignee}' : v.status),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _setStatus(v, 'closed'),
            child: const Text('Postpone'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => _setStatus(v, 'attended'),
            child: const Text('Allow In'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return Center(
          child: Text(_error!,
              style: const TextStyle(color: AppColors.dangerText)));
    }

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(14),
              border:
                  const Border(left: BorderSide(color: AppColors.primary, width: 4)),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Visitor Queue',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                ),
                Text('${_visitors.length} waiting',
                    style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_visitors.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(
                child: Text('No visitors in the queue.',
                    style: TextStyle(color: AppColors.textMuted)),
              ),
            )
          else
            ..._visitors.map((v) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildVisitorTile(v),
                )),
        ],
      ),
    );
  }

  Widget _buildVisitorTile(Visitor v) {
    final waiting = v.status == 'pending';
    return InkWell(
      onTap: () => _openDetail(v),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.14),
              foregroundColor: AppColors.primaryDark,
              child: Text(_initials(v.name),
                  style:
                      const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(v.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700)),
                      ),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (waiting ? AppColors.warning : AppColors.primary)
                              .withOpacity(0.14),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          waiting ? 'WAITING' : 'ASSIGNED',
                          style: TextStyle(
                            color: waiting
                                ? const Color(0xFFB45309)
                                : AppColors.primaryDark,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                      (v.company ?? '').isNotEmpty
                          ? v.company!
                          : 'Individual visitor',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12.5)),
                  const SizedBox(height: 2),
                  Text('Time in ${_timeLabel(v)}',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
