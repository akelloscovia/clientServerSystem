import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/program.dart';
import '../services/kiosk_service.dart';
import '../utils/constants.dart';
import '../widgets/programs_view.dart';
import '../widgets/tv_channel_view.dart';
import '../widgets/kiosk_header.dart';
import '../widgets/news_ticker.dart';
import 'login_screen.dart';

enum _KioskMode { programs, split, tv }

/// Reception kiosk screen — shown by default on the reception device.
/// Switches between the daily program schedule, TV channels, or both side
/// by side (either side can hold either pane), and always shows a QR code
/// visitors can scan to fill in the sign-in form.
class KioskHomeScreen extends StatefulWidget {
  const KioskHomeScreen({super.key});

  @override
  State<KioskHomeScreen> createState() => _KioskHomeScreenState();
}

class _KioskHomeScreenState extends State<KioskHomeScreen> {
  static const _dayNames = [
    'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
  ];

  _KioskMode _mode = _KioskMode.split;
  // Split mode only: which pane sits on the right.
  bool _tvOnRight = true;

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
      // Ticker is decorative — silently skip if the programs fetch fails.
    }
  }

  String _tickerLabel(Program program) {
    String label(String hhmm) {
      final parts = hhmm.split(':');
      final h = int.tryParse(parts[0]) ?? 0;
      final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      final dt = DateTime(2000, 1, 1, h, m);
      return DateFormat('h:mma').format(dt).toLowerCase();
    }

    final where = (program.location ?? '').isNotEmpty ? ' (${program.location})' : '';
    return '${program.title} · ${label(program.startTime)}–${label(program.endTime)}$where';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0d14),
      body: SafeArea(
        child: Column(
          children: [
            KioskHeader(
              trailing: IconButton(
                icon: const Icon(Icons.login, color: Colors.white),
                tooltip: 'Staff login',
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen())),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth > 800;
                  final main = Column(
                    children: [
                      _buildToggle(),
                      Expanded(child: _buildContent()),
                    ],
                  );
                  if (wide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: main),
                        SizedBox(width: 280, child: _buildQrPanel(vertical: true)),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      Expanded(child: main),
                      _buildQrPanel(vertical: false),
                    ],
                  );
                },
              ),
            ),
            NewsTicker(items: _tickerItems),
          ],
        ),
      ),
    );
  }

  Widget _buildToggle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _toggleButton('📅  Programs', _mode == _KioskMode.programs,
                () => setState(() => _mode = _KioskMode.programs)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _toggleButton('◨  Split', _mode == _KioskMode.split,
                () => setState(() => _mode = _KioskMode.split)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _toggleButton('📺  TV', _mode == _KioskMode.tv,
                () => setState(() => _mode = _KioskMode.tv)),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_mode) {
      case _KioskMode.programs:
        return const ProgramsView();
      case _KioskMode.tv:
        return const TvChannelView();
      case _KioskMode.split:
        return _buildSplitView();
    }
  }

  /// Programs and TV shown together, either side of a divider with a swap
  /// button so either pane can sit on the left or right.
  Widget _buildSplitView() {
    const programsPane = ProgramsView();
    const tvPane = TvChannelView();
    final left = _tvOnRight ? programsPane : tvPane;
    final right = _tvOnRight ? tvPane : programsPane;

    final swapButton = IconButton(
      tooltip: 'Swap sides',
      icon: const Icon(Icons.swap_horiz, color: Color(0xFF94a3b8)),
      onPressed: () => setState(() => _tvOnRight = !_tvOnRight),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final sideBySide = constraints.maxWidth > 560;
        final divider = Container(
          width: sideBySide ? 1 : double.infinity,
          height: sideBySide ? double.infinity : 1,
          color: const Color(0x12FFFFFF),
        );

        if (sideBySide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: left),
              SizedBox(
                width: 44,
                child: Column(
                  children: [
                    Expanded(child: divider),
                    swapButton,
                    Expanded(child: divider),
                  ],
                ),
              ),
              Expanded(child: right),
            ],
          );
        }
        return Column(
          children: [
            Expanded(child: left),
            Row(
              children: [Expanded(child: divider), swapButton, Expanded(child: divider)],
            ),
            Expanded(child: right),
          ],
        );
      },
    );
  }

  Widget _toggleButton(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF3b82f6).withOpacity(0.2)
              : const Color(0xFF111827),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? const Color(0xFF3b82f6) : const Color(0x12FFFFFF),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: active ? const Color(0xFF60a5fa) : const Color(0xFF94a3b8),
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQrPanel({required bool vertical}) {
    final qrSize = vertical ? 160.0 : 96.0;
    final qrCode = Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: QrImageView(
        data: AppConstants.visitorFormUrl,
        version: QrVersions.auto,
        size: qrSize,
      ),
    );

    final title = Text('Visitor Sign-In',
        style: const TextStyle(
            color: Color(0xFFF1F5F9), fontWeight: FontWeight.w700, fontSize: 16),
        textAlign: vertical ? TextAlign.center : TextAlign.left);
    final subtitle = Text('Scan to check in',
        style: const TextStyle(color: Color(0xFF64748b), fontSize: 12),
        textAlign: vertical ? TextAlign.center : TextAlign.left);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x12FFFFFF)),
      ),
      child: vertical
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [title, const SizedBox(height: 4), subtitle, const SizedBox(height: 16), qrCode],
            )
          : Row(
              children: [
                qrCode,
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [title, const SizedBox(height: 4), subtitle],
                  ),
                ),
              ],
            ),
    );
  }
}
