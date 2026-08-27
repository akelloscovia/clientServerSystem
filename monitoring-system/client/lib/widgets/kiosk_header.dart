import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart';

/// Top branding bar for the reception kiosk: org name on the left, a live
/// clock and date on the right, on a blue gradient background.
class KioskHeader extends StatefulWidget {
  final Widget? trailing;

  const KioskHeader({super.key, this.trailing});

  @override
  State<KioskHeader> createState() => _KioskHeaderState();
}

class _KioskHeaderState extends State<KioskHeader> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1d4ed8), Color(0xFF2563eb)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.account_balance, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppConstants.orgName.toUpperCase(),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ),
          if (widget.trailing != null) ...[
            widget.trailing!,
            const SizedBox(width: 16),
          ],
          Container(
            width: 1,
            height: 32,
            color: Colors.white.withOpacity(0.25),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat('h:mm').format(_now),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('EEEE, MMMM d, yyyy').format(_now).toUpperCase(),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
