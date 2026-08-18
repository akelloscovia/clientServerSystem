import 'package:flutter/material.dart';
import '../models/submission.dart';
import '../models/response.dart';
import '../services/submission_service.dart';
import '../utils/constants.dart';

class SubmissionStatusScreen extends StatefulWidget {
  final int submissionId;
  const SubmissionStatusScreen({super.key, required this.submissionId});

  @override
  State<SubmissionStatusScreen> createState() => _SubmissionStatusScreenState();
}

class _SubmissionStatusScreenState extends State<SubmissionStatusScreen> {
  final _service = SubmissionService();
  Submission? _submission;
  List<SubmissionResponse> _responses = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        _service.getSubmission(widget.submissionId),
        _service.getResponses(widget.submissionId),
      ]);
      setState(() {
        _submission = results[0] as Submission;
        _responses  = results[1] as List<SubmissionResponse>;
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'pending':      return const Color(0xFFf59e0b);
      case 'under_review': return const Color(0xFF6366f1);
      case 'assigned':     return const Color(0xFF3b82f6);
      case 'resolved':     return const Color(0xFF10b981);
      case 'closed':       return const Color(0xFF64748b);
      default:             return const Color(0xFF64748b);
    }
  }

  String _formatDate(String? iso) {
    if (iso == null) return '—';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return '${dt.day.toString().padLeft(2, '0')} '
           '${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][dt.month - 1]} '
           '${dt.year}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildStatusStep(String label, String status, String currentStatus) {
    final order = ['pending', 'under_review', 'assigned', 'resolved', 'closed'];
    final current = order.indexOf(currentStatus);
    final step    = order.indexOf(status);
    final isDone  = step <= current;
    final isActive = status == currentStatus;

    return Row(
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone ? _statusColor(status) : const Color(0xFF1a2235),
            border: Border.all(
              color: isActive ? _statusColor(status) : const Color(0x20FFFFFF),
              width: 2,
            ),
          ),
          child: isDone
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : null,
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: isActive
                ? _statusColor(status)
                : isDone
                    ? const Color(0xFF94a3b8)
                    : const Color(0xFF475569),
            fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0d14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0d1117),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF94a3b8), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Case #${widget.submissionId}',
          style: const TextStyle(color: Color(0xFFF1F5F9),
            fontSize: 18, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF94a3b8)),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3b82f6)))
          : _error != null
              ? Center(child: Text(_error!,
                  style: const TextStyle(color: Color(0xFFfca5a5))))
              : RefreshIndicator(
                  color: const Color(0xFF3b82f6),
                  backgroundColor: const Color(0xFF111827),
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Submission info
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111827),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0x12FFFFFF)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_submission!.title,
                              style: const TextStyle(
                                color: Color(0xFFF1F5F9),
                                fontSize: 18, fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(_submission!.description,
                              style: const TextStyle(
                                color: Color(0xFF94a3b8), fontSize: 14, height: 1.6)),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8, runSpacing: 8,
                              children: [
                                _Chip(label: _submission!.category, icon: Icons.folder_outlined),
                                _Chip(label: _submission!.priority, icon: Icons.flag_outlined),
                                _Chip(
                                  label: _formatDate(_submission!.createdAt),
                                  icon: Icons.access_time,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Status tracker
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111827),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0x12FFFFFF)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Status Progress',
                              style: TextStyle(
                                color: Color(0xFFF1F5F9),
                                fontSize: 15, fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildStatusStep('Pending',     'pending',      _submission!.status),
                            const _StepConnector(),
                            _buildStatusStep('Under Review','under_review', _submission!.status),
                            const _StepConnector(),
                            _buildStatusStep('Assigned',    'assigned',     _submission!.status),
                            const _StepConnector(),
                            _buildStatusStep('Resolved',    'resolved',     _submission!.status),
                            const _StepConnector(),
                            _buildStatusStep('Closed',      'closed',       _submission!.status),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Responses
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111827),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0x12FFFFFF)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('Responses',
                                  style: TextStyle(color: Color(0xFFF1F5F9),
                                    fontSize: 15, fontWeight: FontWeight.w700)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1a2235),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text('${_responses.length}',
                                    style: const TextStyle(
                                      color: Color(0xFF94a3b8), fontSize: 12)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            if (_responses.isEmpty)
                              const Text(
                                'No responses yet. Our team will get back to you soon.',
                                style: TextStyle(color: Color(0xFF64748b), fontSize: 13),
                              )
                            else
                              ...(_responses.map((r) => _ResponseBubble(response: r, formatDate: _formatDate))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _Chip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1a2235),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x12FFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF64748b)),
          const SizedBox(width: 5),
          Text(label,
            style: const TextStyle(color: Color(0xFF94a3b8), fontSize: 12)),
        ],
      ),
    );
  }
}

class _StepConnector extends StatelessWidget {
  const _StepConnector();
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(left: 13, top: 2, bottom: 2),
    width: 2, height: 16,
    color: const Color(0x20FFFFFF),
  );
}

class _ResponseBubble extends StatelessWidget {
  final SubmissionResponse response;
  final String Function(String?) formatDate;
  const _ResponseBubble({required this.response, required this.formatDate});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1a2235),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3b82f6).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: const Color(0xFF3b82f6).withOpacity(0.3),
                child: Text(
                  (response.responder ?? 'A')[0].toUpperCase(),
                  style: const TextStyle(color: Color(0xFF60a5fa),
                    fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              Text(response.responder ?? 'Staff',
                style: const TextStyle(color: Color(0xFFF1F5F9),
                  fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF3b82f6).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(response.responderRole ?? 'staff',
                  style: const TextStyle(color: Color(0xFF60a5fa), fontSize: 10,
                    fontWeight: FontWeight.w700)),
              ),
              const Spacer(),
              Text(formatDate(response.createdAt),
                style: const TextStyle(color: Color(0xFF475569), fontSize: 11)),
            ],
          ),
          const SizedBox(height: 10),
          Text(response.message,
            style: const TextStyle(color: Color(0xFF94a3b8), fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }
}
