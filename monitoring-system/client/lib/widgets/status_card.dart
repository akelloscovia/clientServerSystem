import 'package:flutter/material.dart';
import '../models/submission.dart';

/// Card displaying a submission's status and metadata.
class StatusCard extends StatelessWidget {
  final Submission submission;
  final VoidCallback? onTap;

  const StatusCard({super.key, required this.submission, this.onTap});

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':      return const Color(0xFFf59e0b);
      case 'under_review': return const Color(0xFF6366f1);
      case 'assigned':     return const Color(0xFF3b82f6);
      case 'resolved':     return const Color(0xFF10b981);
      case 'closed':       return const Color(0xFF64748b);
      default:             return const Color(0xFF64748b);
    }
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'urgent': return const Color(0xFFef4444);
      case 'high':   return const Color(0xFFf59e0b);
      case 'medium': return const Color(0xFF6366f1);
      case 'low':    return const Color(0xFF10b981);
      default:       return const Color(0xFF64748b);
    }
  }

  String _formatDate(String? iso) {
    if (iso == null) return '—';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return '${dt.day.toString().padLeft(2, '0')} '
           '${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][dt.month - 1]} '
           '${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x14000000)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + status
            Row(
              children: [
                Expanded(
                  child: Text(submission.title,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _Badge(
                  label: submission.status.replaceAll('_', ' '),
                  color: _statusColor(submission.status),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Description preview
            Text(
              submission.description,
              style: const TextStyle(color: Color(0xFF475569), fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            // Meta row
            Row(
              children: [
                _MetaChip(label: submission.category, icon: Icons.folder_outlined),
                const SizedBox(width: 8),
                _Badge(
                  label: submission.priority,
                  color: _priorityColor(submission.priority),
                  small: true,
                ),
                const Spacer(),
                Text(_formatDate(submission.createdAt),
                  style: const TextStyle(color: Color(0xFF64748b), fontSize: 12)),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: Color(0xFF64748b), size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final bool small;
  const _Badge({required this.label, required this.color, this.small = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical:   small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: small ? 10 : 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _MetaChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF64748b)),
        const SizedBox(width: 4),
        Text(label,
          style: const TextStyle(
            color: Color(0xFF64748b),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
