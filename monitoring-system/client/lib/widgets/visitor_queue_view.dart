import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/visitor.dart';
import '../services/auth_service.dart';
import '../services/submission_service.dart';
import '../services/visitor_service.dart';
import '../services/notification_realtime_service.dart';
import '../utils/app_colors.dart';

/// The Minister's visitor queue: everyone still waiting to be seen (status
/// `waiting`, `pending`, or `assigned`), with quick Allow In / Postpone actions. Sits
/// alongside [ProgramsView] as the other half of [KioskHomeView]'s
/// Reception/Minister toggle.
class VisitorQueueView extends StatefulWidget {
  final ValueChanged<bool>? onDialogChanged;

  const VisitorQueueView({super.key, this.onDialogChanged});

  @override
  State<VisitorQueueView> createState() => _VisitorQueueViewState();
}

class _VisitorQueueViewState extends State<VisitorQueueView> {
  final _service = VisitorService();
  List<Visitor> _visitors = [];
  bool _loading = true;
  int? _updatingVisitorId;
  String? _error;
  Timer? _pollTimer;
  final _realtime = NotificationRealtimeService();

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(const Duration(seconds: 20), (_) => _load());
    _realtime.addListener(_onRealtimeEvent);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _realtime.removeListener(_onRealtimeEvent);
    super.dispose();
  }

  void _onRealtimeEvent(Map<String, dynamic> event) {
    if (event['type'] == 'visitor.updated') _load();
  }

  Future<void> _load() async {
    if (_visitors.isEmpty && mounted) setState(() => _loading = true);
    try {
      final all = await _service.list();
      final waiting = all
          .where((v) =>
              v.status == 'waiting' ||
              v.status == 'pending' ||
              v.status == 'assigned')
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

  Future<bool> _setStatus(Visitor v, String status) async {
    setState(() => _updatingVisitorId = v.id);
    try {
      await _service.updateStatus(v.id, status);
      if (status == 'attended') {
        final ministerName = AuthService().currentUser?.name ?? 'The minister';
        final message = '$ministerName is ready to meet ${v.name}.';
        // The status action must not wait for optional notification delivery.
        SubmissionService().notifySecretaries(message).catchError((_) {});
      }
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
      return false;
    } finally {
      if (mounted && _updatingVisitorId == v.id) {
        setState(() => _updatingVisitorId = null);
      }
    }
  }

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p[0]).join().toUpperCase();
  }

  /// "Sep 10, 10:00am" when the visit date is known, otherwise just the time
  /// — the date is what lets a viewer tell entries from different days apart
  /// in a queue that's ordered chronologically rather than by time-of-day.
  String _timeLabel(Visitor v) {
    if (v.timeIn == null || v.timeIn!.isEmpty) return '--';
    final parts = v.timeIn!.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    final timeStr =
        DateFormat('h:mma').format(DateTime(2000, 1, 1, h, m)).toLowerCase();
    final visitDate = DateTime.tryParse(v.visitDate ?? '');
    if (visitDate == null) return timeStr;
    return '${DateFormat('MMM d').format(visitDate)}, $timeStr';
  }

  void _openDetail(Visitor v) {
    var submitting = false;
    widget.onDialogChanged?.call(true);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> submit(String status) async {
            if (submitting) return;
            setDialogState(() => submitting = true);
            final updated = await _setStatus(v, status);
            if (!dialogContext.mounted) return;
            if (updated) {
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(
                  content: Text(status == 'attended'
                      ? '${v.name} has been allowed in.'
                      : '${v.name} has been postponed.'),
                ),
              );
              if (status == 'attended' && mounted) {
                setState(() {
                  _visitors =
                      _visitors.where((visitor) => visitor.id != v.id).toList();
                });
              }
              _load();
            } else {
              setDialogState(() => submitting = false);
            }
          }

          return AlertDialog(
            title: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.14),
                  foregroundColor: AppColors.primaryDark,
                  child: Text(_initials(v.name),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(v.name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _detailRow(
                      'Organization',
                      (v.company ?? '').isNotEmpty
                          ? v.company!
                          : 'Individual visitor'),
                  _detailRow('Reason', v.reasonForVisit),
                  if ((v.description ?? '').isNotEmpty)
                    _detailRow('Details', v.description!),
                  _detailRow('Time in', _timeLabel(v)),
                  _detailRow(
                      'Status',
                      v.assignee != null
                          ? '${v.status} · ${v.assignee}'
                          : v.status),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: (v.status == 'waiting'
                              ? const Color(0xFF0EA5E9)
                              : v.status == 'pending'
                                  ? AppColors.warning
                                  : AppColors.primary)
                          .withOpacity(0.14),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      v.status == 'waiting'
                          ? 'WAITING FOR ACTION'
                          : v.status == 'pending'
                              ? 'PENDING'
                              : 'READY FOR ACTION',
                      style: TextStyle(
                        color: v.status == 'waiting'
                            ? const Color(0xFF0369A1)
                            : v.status == 'pending'
                                ? const Color(0xFFB45309)
                                : AppColors.primaryDark,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => submit('pending'),
                child: const Text('Postpone'),
              ),
              FilledButton(
                style:
                    FilledButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () => submit('attended'),
                child: submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Allow In'),
              ),
            ],
          );
        },
      ),
    ).whenComplete(() => widget.onDialogChanged?.call(false));
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
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 12.5)),
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
              border: const Border(
                  left: BorderSide(color: AppColors.primary, width: 4)),
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
    final isWaiting = v.status == 'waiting';
    final isPending = v.status == 'pending';
    final statusColor = isWaiting
        ? const Color(0xFF0EA5E9)
        : isPending
            ? AppColors.warning
            : AppColors.primary;
    final statusLabel = isWaiting
        ? 'WAITING'
        : isPending
            ? 'PENDING'
            : 'ASSIGNED';
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
              backgroundColor: statusColor.withOpacity(0.14),
              foregroundColor:
                  isPending ? const Color(0xFFB45309) : AppColors.primaryDark,
              child: Text(_initials(v.name),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13)),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            color: isPending
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
