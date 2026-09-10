import 'package:flutter/material.dart';

/// The Ministry crest, shown on the kiosk header and the staff login screen.
///
/// The image lives at `assets/ministry_logo.jpg`. It's a round emblem on a
/// white background, so it's placed on a white disc to read cleanly on both
/// the blue header and the light login screen. If the asset can't be loaded
/// the widget falls back to a neutral icon so the UI never breaks.
class MinistryLogo extends StatelessWidget {
  /// Rendered width/height of the white disc in logical pixels.
  final double size;

  /// Colour of the fallback icon (used only when the asset can't be loaded).
  final Color fallbackColor;

  const MinistryLogo({
    super.key,
    this.size = 44,
    this.fallbackColor = const Color(0xFF1D4ED8),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.06),
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/ministry_logo.jpg',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.account_balance,
          size: size * 0.6,
          color: fallbackColor,
        ),
      ),
    );
  }
}
