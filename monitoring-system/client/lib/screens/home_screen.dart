import 'package:flutter/material.dart';
import '../models/submission.dart';
import '../services/auth_service.dart';
import '../services/submission_service.dart';
import '../widgets/status_card.dart';
import 'submission_screen.dart';
import 'submission_status_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _subService  = SubmissionService();
  final _authService = AuthService();
  List<Submission> _submissions = [];
  bool _loading  = true;
  String? _error;
  String _filter = '';
  int _unread    = 0;

  final _filters = ['', 'pending', 'under_review', 'assigned', 'resolved', 'closed'];
  final _filterLabels = {
    '': 'All', 'pending': 'Pending', 'under_review': 'In Review',
    'assigned': 'Assigned', 'resolved': 'Resolved', 'closed': 'Closed',
  };

  @override
  void initState() {
    super.initState();
    _load();
    _loadNotifications();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final items = await _subService.getMySubmissions(
        status: _filter.isEmpty ? null : _filter,
      );
      setState(() => _submissions = items);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadNotifications() async {
    try {
      final data = await _subService.getNotifications();
      setState(() => _unread = data['unread_count'] as int? ?? 0);
    } catch (_) {}
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFF0a0d14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0d1117),
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3b82f6), Color(0xFF8b5cf6)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.bolt, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text('MonitorSys',
              style: TextStyle(color: Color(0xFFF1F5F9),
                fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          // Notification bell
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                  color: Color(0xFF94a3b8)),
                onPressed: _loadNotifications,
              ),
              if (_unread > 0)
                Positioned(
                  right: 8, top: 8,
                  child: Container(
                    width: 16, height: 16,
                    decoration: const BoxDecoration(
                      color: Color(0xFFef4444),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text('$_unread',
                        style: const TextStyle(color: Colors.white,
                          fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF94a3b8)),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          // Welcome banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hello, ${user?.name.split(' ').first ?? 'User'} 👋',
                  style: const TextStyle(color: Color(0xFFF1F5F9),
                    fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                const Text('Track and manage your submissions below.',
                  style: TextStyle(color: Color(0xFF64748b), fontSize: 14)),
              ],
            ),
          ),

          // Filter chips
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f = _filters[i];
                final active = _filter == f;
                return GestureDetector(
                  onTap: () { setState(() => _filter = f); _load(); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: active
                          ? const Color(0xFF3b82f6).withOpacity(0.2)
                          : const Color(0xFF1a2235),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: active
                            ? const Color(0xFF3b82f6)
                            : const Color(0x12FFFFFF),
                      ),
                    ),
                    child: Text(_filterLabels[f]!,
                      style: TextStyle(
                        color: active
                            ? const Color(0xFF60a5fa)
                            : const Color(0xFF94a3b8),
                        fontSize: 13,
                        fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Submissions list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF3b82f6)))
                : _error != null
                    ? Center(child: Text(_error!,
                        style: const TextStyle(color: Color(0xFFfca5a5))))
                    : _submissions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.inbox_outlined,
                                  size: 64, color: Color(0xFF334155)),
                                const SizedBox(height: 12),
                                const Text('No submissions yet.',
                                  style: TextStyle(color: Color(0xFF64748b), fontSize: 15)),
                                const SizedBox(height: 8),
                                const Text('Tap + to submit a new case.',
                                  style: TextStyle(color: Color(0xFF475569), fontSize: 13)),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            color: const Color(0xFF3b82f6),
                            backgroundColor: const Color(0xFF111827),
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                              itemCount: _submissions.length,
                              itemBuilder: (_, i) => StatusCard(
                                submission: _submissions[i],
                                onTap: () async {
                                  await Navigator.push(context,
                                    MaterialPageRoute(
                                      builder: (_) => SubmissionStatusScreen(
                                        submissionId: _submissions[i].id,
                                      ),
                                    ),
                                  );
                                  _load();
                                },
                              ),
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context,
            MaterialPageRoute(builder: (_) => const SubmissionScreen()));
          _load();
        },
        backgroundColor: const Color(0xFF3b82f6),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Case',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
