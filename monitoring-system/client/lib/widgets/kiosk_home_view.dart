import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import 'programs_view.dart';
import 'tv_channel_view.dart';

/// The reception "home" screen: today's programme schedule and the TV
/// channels shown side by side (either one can be swapped to the other
/// side). Visitors sign in by scanning the printed QR code at reception,
/// which opens the web visitor form — see `AppConstants.visitorFormUrl`.
class KioskHomeView extends StatefulWidget {
  const KioskHomeView({super.key});

  @override
  State<KioskHomeView> createState() => _KioskHomeViewState();
}

class _KioskHomeViewState extends State<KioskHomeView> {
  bool _tvOnRight = true;

  @override
  Widget build(BuildContext context) {
    const programsPane = ProgramsView();
    const tvPane = TvChannelView();
    final left = _tvOnRight ? programsPane : tvPane;
    final right = _tvOnRight ? tvPane : programsPane;

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
