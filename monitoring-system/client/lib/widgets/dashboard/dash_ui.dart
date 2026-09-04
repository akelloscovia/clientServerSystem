import 'package:flutter/material.dart';

/// Shared colours + small building blocks for the staff dashboard sections,
/// so every section (cases, programmes, channels, visitors, users, overview)
/// looks like one surface.
class Dash {
  static const bg = Color(0xFF0a0d14);
  static const card = Color(0xFF111827);
  static const field = Color(0xFF1a2235);
  static const line = Color(0x12FFFFFF);
  static const primary = Color(0xFF3b82f6);
  static const primaryText = Color(0xFF60a5fa);
  static const ink = Color(0xFFF1F5F9);
  static const dim = Color(0xFF94a3b8);
  static const faint = Color(0xFF64748b);
  static const danger = Color(0xFFef4444);
  static const ok = Color(0xFF10b981);

  static BoxDecoration get cardBox => BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: line),
      );

  /// Status colours reused from [SubmissionStatusScreen] for consistency.
  static Color caseStatus(String s) {
    switch (s) {
      case 'pending':
        return const Color(0xFFf59e0b);
      case 'under_review':
        return const Color(0xFF6366f1);
      case 'assigned':
        return const Color(0xFF3b82f6);
      case 'resolved':
        return const Color(0xFF10b981);
      case 'closed':
        return const Color(0xFF64748b);
      default:
        return const Color(0xFF64748b);
    }
  }

  static Color visitorStatus(String s) {
    switch (s) {
      case 'pending':
        return const Color(0xFFf59e0b);
      case 'assigned':
        return const Color(0xFF3b82f6);
      case 'attended':
        return const Color(0xFF10b981);
      case 'closed':
        return const Color(0xFF64748b);
      default:
        return const Color(0xFF64748b);
    }
  }

  static InputDecoration input(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: dim, fontSize: 13),
        hintStyle: const TextStyle(color: faint),
        filled: true,
        fillColor: field,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
      );
}

/// Wraps a section body with consistent loading / error / empty handling.
class SectionState extends StatelessWidget {
  final bool loading;
  final String? error;
  final bool empty;
  final String emptyText;
  final Future<void> Function() onRetry;
  final Widget child;

  const SectionState({
    super.key,
    required this.loading,
    required this.error,
    required this.empty,
    required this.emptyText,
    required this.onRetry,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
          child: CircularProgressIndicator(color: Dash.primary));
    }
    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFfca5a5))),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (empty) {
      return Center(
        child: Text(emptyText, style: const TextStyle(color: Dash.faint)),
      );
    }
    return child;
  }
}

/// Section header row: title + optional trailing action (e.g. "Add").
class SectionHeader extends StatelessWidget {
  final String title;
  final String? count;
  final Widget? action;
  const SectionHeader(this.title, {super.key, this.count, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
      child: Row(
        children: [
          Text(title,
              style: const TextStyle(
                  color: Dash.ink, fontSize: 18, fontWeight: FontWeight.w700)),
          if (count != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: Dash.field, borderRadius: BorderRadius.circular(99)),
              child: Text(count!,
                  style: const TextStyle(color: Dash.dim, fontSize: 12)),
            ),
          ],
          const Spacer(),
          if (action != null) action!,
        ],
      ),
    );
  }
}
