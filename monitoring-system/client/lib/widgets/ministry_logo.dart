import 'package:flutter/material.dart';

/// The Ministry crest, shown on the kiosk header and the staff login screen.
///
/// The image lives at `assets/ministry_logo.png`. If that file is missing the
/// widget falls back to a neutral icon so the UI never breaks.
class MinistryLogo extends StatelessWidget {
  /// Rendered width/height in logical pixels.
  final double size;

  /// Colour of the fallback icon (used only when the asset can't be loaded).
  final Color fallbackColor;

  const MinistryLogo({
    super.key,
    this.size = 44,
    this.fallbackColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/ministry_logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.account_balance,
        size: size * 0.9,
        color: fallbackColor,
      ),
    );
  }
}
