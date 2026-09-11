import 'package:flutter/material.dart';

/// Scrolling ticker bar shown at the bottom of the kiosk, with a "LATEST"
/// badge followed by an endlessly scrolling line of announcements.
class NewsTicker extends StatefulWidget {
  final List<String> items;

  const NewsTicker({super.key, required this.items});

  @override
  State<NewsTicker> createState() => _NewsTickerState();
}

class _NewsTickerState extends State<NewsTicker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _style = TextStyle(
    color: Color(0xFFcbd5e1),
    fontSize: 17,
    fontWeight: FontWeight.w600,
  );
  static const _gap = '     •     ';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 20));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _textWidth(String text, double maxWidth) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: _style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    return painter.width;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();
    final segment = widget.items.join(_gap) + _gap;

    return Container(
      height: 48,
      color: const Color(0xFF0d1117),
      child: Row(
        children: [
          Container(
            height: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            color: const Color(0xFFdc2626),
            alignment: Alignment.center,
            child: const Text(
              'LATEST',
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: ClipRect(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final segmentWidth = _textWidth(segment, double.infinity);
                  final durationSeconds = (segmentWidth / 60).clamp(8, 60).toDouble();
                  _controller.duration = Duration(milliseconds: (durationSeconds * 1000).round());
                  if (!_controller.isAnimating) _controller.repeat();

                  return AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      final dx = -(_controller.value * segmentWidth);
                      return Stack(
                        children: [
                          Positioned(
                            left: dx,
                            top: 0,
                            bottom: 0,
                            child: Row(
                              children: [
                                Center(child: Text(segment, maxLines: 1, style: _style)),
                                Center(child: Text(segment, maxLines: 1, style: _style)),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
