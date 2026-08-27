import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/program.dart';
import '../services/kiosk_service.dart';
import '../utils/constants.dart';

/// Shows today's ministry program schedule: a "Next Up" (or "Now Showing")
/// hero card with a live countdown, followed by the full day's schedule.
class ProgramsView extends StatefulWidget {
  const ProgramsView({super.key});

  @override
  State<ProgramsView> createState() => _ProgramsViewState();
}

class _ProgramsViewState extends State<ProgramsView> {
  static const _dayNames = [
    'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
  ];

  final _kiosk = KioskService();
  List<Program> _programs = [];
  bool _loading = true;
  String? _error;
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
    _clockTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final today = _dayNames[DateTime.now().weekday - 1];
      final programs = await _kiosk.getPrograms(day: today);
      programs.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
      if (!mounted) return;
      setState(() {
        _programs = programs;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  DateTime _timeOn(String hhmm) {
    final parts = hhmm.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return DateTime(_now.year, _now.month, _now.day, h, m);
  }

  String _timeLabel(String hhmm) =>
      DateFormat('h:mma').format(_timeOn(hhmm)).toLowerCase();

  String _countdownLabel(int minutes) {
    final clamped = minutes < 0 ? 0 : minutes;
    final h = clamped ~/ 60;
    final m = clamped % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF3b82f6)));
    }
    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Color(0xFFfca5a5))),
      );
    }
    if (_programs.isEmpty) {
      return const Center(
        child: Text('No programs scheduled for today.',
            style: TextStyle(color: Color(0xFF64748b))),
      );
    }

    final nowMinutes = _now.hour * 60 + _now.minute;
    final current = _programs.where((p) => p.isHappeningNow(_now)).toList();
    final currentProgram = current.isNotEmpty ? current.first : null;
    final upcoming = _programs.where((p) => p.startMinutes > nowMinutes).toList()
      ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    final nextProgram = upcoming.isNotEmpty ? upcoming.first : null;

    return RefreshIndicator(
      color: const Color(0xFF3b82f6),
      backgroundColor: const Color(0xFF111827),
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (currentProgram != null)
            _buildHeroCard(
              label: 'Now Showing',
              program: currentProgram,
              countdown: _countdownLabel(currentProgram.endMinutes - nowMinutes),
              countdownSuffix: 'left',
            )
          else if (nextProgram != null)
            _buildHeroCard(
              label: 'Next Up',
              program: nextProgram,
              countdown: _countdownLabel(nextProgram.startMinutes - nowMinutes),
              countdownSuffix: '',
            ),
          if (currentProgram != null || nextProgram != null)
            const SizedBox(height: 16),
          ..._programs.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildProgramTile(p, isNow: p.id == currentProgram?.id),
              )),
        ],
      ),
    );
  }

  Widget _buildHeroCard({
    required String label,
    required Program program,
    required String countdown,
    required String countdownSuffix,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16233b),
        borderRadius: BorderRadius.circular(14),
        border: const Border(
          left: BorderSide(color: Color(0xFFf5b542), width: 4),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Color(0xFF94a3b8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4)),
                const SizedBox(height: 4),
                Text(program.title,
                    style: const TextStyle(
                        color: Color(0xFFF1F5F9),
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Text(
            countdownSuffix.isEmpty ? countdown : '$countdown $countdownSuffix',
            style: const TextStyle(
                color: Color(0xFFf5b542),
                fontSize: 20,
                fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildProgramTile(Program program, {required bool isNow}) {
    final dayLabel = DateFormat('EEE, d MMM').format(_now);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isNow
            ? const Color(0xFF3b82f6).withOpacity(0.12)
            : const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isNow ? const Color(0xFF3b82f6) : const Color(0x12FFFFFF),
          width: isNow ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Text(_timeLabel(program.startTime),
                style: const TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        program.title,
                        style: const TextStyle(
                            color: Color(0xFFF1F5F9),
                            fontWeight: FontWeight.w700,
                            fontSize: 15),
                      ),
                    ),
                    if (isNow)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3b82f6),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: const Text('NOW',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.schedule, size: 13, color: Color(0xFF64748b)),
                        const SizedBox(width: 4),
                        Text(
                          '$dayLabel · ${_timeLabel(program.startTime)}–${_timeLabel(program.endTime)}',
                          style: const TextStyle(color: Color(0xFF64748b), fontSize: 12),
                        ),
                      ],
                    ),
                    if ((program.location ?? '').isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on, size: 13, color: Color(0xFF64748b)),
                          const SizedBox(width: 4),
                          Text(program.location!,
                              style: const TextStyle(color: Color(0xFF64748b), fontSize: 12)),
                        ],
                      ),
                  ],
                ),
                if ((program.description ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(program.description!,
                      style: const TextStyle(color: Color(0xFF94a3b8), fontSize: 13)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1a2235),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0x12FFFFFF)),
            ),
            child: const Text(AppConstants.orgTag,
                style: TextStyle(
                    color: Color(0xFF60a5fa),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3)),
          ),
        ],
      ),
    );
  }
}
