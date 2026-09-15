import 'package:flutter/material.dart';
import '../services/auth_service.dart';
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

  bool get _canSeeMinisterView =>
      AuthService().currentUser?.role != 'secretary';

  @override
  Widget build(BuildContext context) {
    final showMinisterView = _canSeeMinisterView && _role == KioskRole.minister;
    final mainPane =
        showMinisterView ? const VisitorQueueView() : const ProgramsView();
    return Column(
      children: [
        if (_canSeeMinisterView) _buildRoleToggle(),
        Expanded(child: _buildSideBySideLayout(mainPane)),
      ],
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
              _roleButton('Minister', KioskRole.minister, Icons.how_to_reg_outlined),
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
    final left = _tvOnRight ? mainPane : tvPane;
    final right = _tvOnRight ? tvPane : mainPane;

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
              children: [Expanded(child: divider), swapButton, Expanded(child: divider)],
            ),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}
