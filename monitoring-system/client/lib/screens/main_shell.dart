import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/program.dart';
import '../services/kiosk_service.dart';
import '../widgets/kiosk_header.dart';
import '../widgets/kiosk_home_view.dart';
import '../widgets/news_ticker.dart';
import '../widgets/visitor_signin_dropdown.dart';

/// The single public-facing kiosk screen: the branded header, today's
/// programme schedule and TV channels (side by side, inside [KioskHomeView]),
/// and a scrolling news ticker along the bottom. There is no in-app
/// navigation — staff reach the dashboard through the separate web portal.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const _dayNames = [
    'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
  ];

  final _kiosk = KioskService();
  List<String> _tickerItems = [];

  @override
  void initState() {
    super.initState();
    _loadTicker();
  }

  Future<void> _loadTicker() async {
    try {
      final today = _dayNames[DateTime.now().weekday - 1];
      final programs = await _kiosk.getPrograms(day: today);
      programs.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
      if (!mounted) return;
      setState(() => _tickerItems = programs.map(_tickerLabel).toList());
    } catch (_) {
      // Ticker is decorative — ignore fetch failures.
    }
  }

  String _tickerLabel(Program program) {
    String label(String hhmm) {
      final parts = hhmm.split(':');
      final h = int.tryParse(parts[0]) ?? 0;
      final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      return DateFormat('h:mma').format(DateTime(2000, 1, 1, h, m)).toLowerCase();
    }

    final where =
        (program.location ?? '').isNotEmpty ? ' (${program.location})' : '';
    return '${program.title} · ${label(program.startTime)}–${label(program.endTime)}$where';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F6),
      body: SafeArea(
        child: Column(
          children: [
            const KioskHeader(trailing: VisitorSignInDropdown()),
            const Expanded(child: KioskHomeView()),
            NewsTicker(items: _tickerItems),
          ],
        ),
      ),
    );
  }
}
