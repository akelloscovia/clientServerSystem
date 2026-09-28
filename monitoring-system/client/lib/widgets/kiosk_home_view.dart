import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/notification_realtime_service.dart';
import '../utils/app_colors.dart';
import 'programs_view.dart';
import 'tv_channel_view.dart';
import 'visitor_queue_view.dart';

enum KioskRole { reception, minister }

/// The kiosk "home" screen. A Reception/Minister toggle switches the main
/// pane between today's programme schedule (Reception) and the Minister's
/// visitor queue — either way the TV channels sit alongside it, and the two
/// sides can be swapped. The visitor queue is Minister-office business, so
/// secretaries only ever see the Reception layout — no toggle is shown.
class KioskHomeView extends StatefulWidget {
  const KioskHomeView({super.key});

  @override
  State<KioskHomeView> createState() => _KioskHomeViewState();
}

class _KioskHomeViewState extends State<KioskHomeView> {
  bool _tvOnRight = true;
  KioskRole _role = KioskRole.reception;
  bool _visitorDialogOpen = false;
  final _realtime = NotificationRealtimeService();
  Timer? _bannerTimer;
  String? _visitorBanner;
  bool _visitorWasAllowedIn = false;

  bool get _canSeeMinisterView =>
      AuthService().currentUser?.role != 'secretary';

  @override
  void initState() {
    super.initState();
    _realtime.addListener(_onRealtimeEvent);
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _realtime.removeListener(_onRealtimeEvent);
    super.dispose();
  }

  void _onRealtimeEvent(Map<String, dynamic> event) {
    if (event['type'] != 'visitor.updated' || !mounted) return;
    final visitor = event['visitor'];
    if (visitor is! Map) return;
    final name = visitor['name'] as String? ?? 'Visitor';
    final status = visitor['status'] as String?;
    if (status != 'attended' && status != 'pending') return;
    _bannerTimer?.cancel();
    setState(() {
      _visitorWasAllowedIn = status == 'attended';
      _visitorBanner = _visitorWasAllowedIn
          ? '$name has been allowed in.'
          : '$name has been postponed.';
    });
    _bannerTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) setState(() => _visitorBanner = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final showMinisterView = _canSeeMinisterView && _role == KioskRole.minister;
    final mainPane = showMinisterView
        ? VisitorQueueView(
            onDialogChanged: (open) =>
                setState(() => _visitorDialogOpen = open),
          )
        : const ProgramsView();
    return Column(
      children: [
        if (_canSeeMinisterView) _buildRoleToggle(),
        if (_role == KioskRole.reception && _visitorBanner != null)
          _buildVisitorBanner(),
        Expanded(child: _buildSideBySideLayout(mainPane)),
      ],
    );
  }

  Widget _buildVisitorBanner() {
    final color = _visitorWasAllowedIn
        ? const Color(0xFF15803D)
        : const Color(0xFFB45309);
    return Material(
      color: color,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            Icon(
              _visitorWasAllowedIn
                  ? Icons.check_circle_outline
                  : Icons.schedule_outlined,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _visitorBanner!,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Dismiss notification',
              onPressed: () => setState(() => _visitorBanner = null),
              icon: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleToggle() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _roleButton('Reception', KioskRole.reception, Icons.tv_outlined),
              _roleButton(
                  'Minister', KioskRole.minister, Icons.how_to_reg_outlined),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleButton(String label, KioskRole role, IconData icon) {
    final active = _role == role;
    return InkWell(
      onTap: () => setState(() => _role = role),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 15,
                color: active ? AppColors.primaryDark : AppColors.textMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: active ? AppColors.primaryDark : AppColors.textMuted,
                fontSize: 13,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideBySideLayout(Widget mainPane) {
    const tvPane = TvChannelView();
    final hiddenTvPane = _visitorDialogOpen ? const SizedBox() : tvPane;
    final left = _tvOnRight ? mainPane : hiddenTvPane;
    final right = _tvOnRight ? hiddenTvPane : mainPane;

    final swapButton = IconButton(
      tooltip: 'Swap sides',
      icon: const Icon(Icons.swap_horiz, color: AppColors.textMuted),
      onPressed: () => setState(() => _tvOnRight = !_tvOnRight),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final sideBySide = constraints.maxWidth > 560;
        final divider = Container(
          width: sideBySide ? 1 : double.infinity,
          height: sideBySide ? double.infinity : 1,
          color: AppColors.border,
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
              children: [
                Expanded(child: divider),
                swapButton,
                Expanded(child: divider)
              ],
            ),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}
