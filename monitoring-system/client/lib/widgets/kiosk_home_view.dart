import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../utils/constants.dart';
import 'programs_view.dart';
import 'tv_channel_view.dart';

enum _KioskMode { programs, split, tv }

/// The reception "home" screen: today's programme schedule and the TV
/// channels shown together (or either one full-width), plus a visitor
/// sign-in panel with both a QR code and an on-screen button for visitors
/// who don't have a phone to hand.
class KioskHomeView extends StatefulWidget {
  /// Called when the visitor taps "Sign in here" — the shell switches to
  /// the Visitor Sign-In tab.
  final VoidCallback onOpenVisitorForm;

  const KioskHomeView({super.key, required this.onOpenVisitorForm});

  @override
  State<KioskHomeView> createState() => _KioskHomeViewState();
}

class _KioskHomeViewState extends State<KioskHomeView> {
  _KioskMode _mode = _KioskMode.split;
  bool _tvOnRight = true;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
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
              SizedBox(width: 300, child: _buildQrPanel(vertical: true)),
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
    final qrSize = vertical ? 150.0 : 88.0;
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
    final subtitle = Text('Scan the code, or sign in on this screen',
        style: const TextStyle(color: Color(0xFF64748b), fontSize: 12),
        textAlign: vertical ? TextAlign.center : TextAlign.left);

    final signInButton = SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: widget.onOpenVisitorForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3b82f6),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: const Icon(Icons.how_to_reg, size: 18),
        label: const Text('Sign in here',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );

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
              children: [
                title,
                const SizedBox(height: 4),
                subtitle,
                const SizedBox(height: 16),
                qrCode,
                const SizedBox(height: 16),
                signInButton,
                const SizedBox(height: 6),
                const Text('No phone needed',
                    style: TextStyle(color: Color(0xFF475569), fontSize: 11)),
              ],
            )
          : Row(
              children: [
                qrCode,
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      title,
                      const SizedBox(height: 4),
                      subtitle,
                      const SizedBox(height: 10),
                      signInButton,
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
