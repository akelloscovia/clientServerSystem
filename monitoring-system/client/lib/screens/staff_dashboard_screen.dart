import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/dashboard/cases_section.dart';
import '../widgets/dashboard/channel_manager.dart';
import '../widgets/dashboard/dash_ui.dart';
import '../widgets/dashboard/dashboard_overview.dart';
import '../widgets/dashboard/program_manager.dart';
import '../widgets/dashboard/user_manager.dart';
import '../widgets/dashboard/visitor_manager.dart';
import 'login_screen.dart';

/// Admin / secretary workspace — a tabbed dashboard.
///
/// Secretary: Cases · Programmes · Visitors.
/// Admin: Overview (charts) · Cases · Programmes · Channels · Visitors · Users.
///
/// When [embedded] is true it drops its own Scaffold + AppBar so it can be
/// hosted inside the [MainShell] Admin Portal tab, and calls [onLoggedOut]
/// instead of navigating on sign out.
class StaffDashboardScreen extends StatefulWidget {
  final bool embedded;
  final VoidCallback? onLoggedOut;

  const StaffDashboardScreen(
      {super.key, this.embedded = false, this.onLoggedOut});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  final _auth = AuthService();

  /// Bumped by the refresh button; every section listens and reloads.
  final _refresh = ValueNotifier<int>(0);

  int _index = 0;
  late final List<_Tab> _tabs;

  bool get _isAdmin => _auth.currentUser?.role == 'admin';

  @override
  void initState() {
    super.initState();
    _tabs = _isAdmin
        ? [
            _Tab('Overview', DashboardOverview(refreshSignal: _refresh)),
            _Tab('Cases',
                CasesSection(isAdmin: true, refreshSignal: _refresh)),
            _Tab('Programmes', ProgramManager(refreshSignal: _refresh)),
            _Tab('Channels', ChannelManager(refreshSignal: _refresh)),
            _Tab('Visitors',
                VisitorManager(isAdmin: true, refreshSignal: _refresh)),
            _Tab('Users', UserManager(refreshSignal: _refresh)),
          ]
        : [
            _Tab('Cases',
                CasesSection(isAdmin: false, refreshSignal: _refresh)),
            _Tab('Programmes', ProgramManager(refreshSignal: _refresh)),
            _Tab('Visitors',
                VisitorManager(isAdmin: false, refreshSignal: _refresh)),
          ];
  }

  @override
  void dispose() {
    _refresh.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await _auth.logout();
    if (!mounted) return;
    if (widget.embedded) {
      widget.onLoggedOut?.call();
    } else {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isAdmin ? 'Admin Dashboard' : 'Secretary Workspace';
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 2),
          child: Row(
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Dash.ink)),
              const Spacer(),
              IconButton(
                tooltip: 'Refresh',
                onPressed: () => _refresh.value++,
                icon: const Icon(Icons.refresh, color: Dash.dim),
              ),
              TextButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Sign out'),
              ),
            ],
          ),
        ),
        _tabBar(),
        Expanded(
          child: IndexedStack(
            index: _index,
            children: _tabs.map((t) => t.body).toList(),
          ),
        ),
      ],
    );

    if (widget.embedded) {
      return Container(color: Dash.bg, child: body);
    }
    return Scaffold(backgroundColor: Dash.bg, body: SafeArea(child: body));
  }

  Widget _tabBar() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final active = i == _index;
          return GestureDetector(
            onTap: () => setState(() => _index = i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active
                    ? Dash.primary.withValues(alpha: 0.2)
                    : Dash.card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: active ? Dash.primary : Dash.line),
              ),
              child: Text(
                _tabs[i].label,
                style: TextStyle(
                  color: active ? Dash.primaryText : Dash.dim,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Tab {
  final String label;
  final Widget body;
  const _Tab(this.label, this.body);
}
