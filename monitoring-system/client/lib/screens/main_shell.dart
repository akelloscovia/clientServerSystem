import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/program.dart';
import '../services/auth_service.dart';
import '../services/kiosk_service.dart';
import '../widgets/kiosk_header.dart';
import '../widgets/kiosk_home_view.dart';
import '../widgets/news_ticker.dart';
import '../widgets/programs_view.dart';
import '../widgets/tv_channel_view.dart';
import 'client_access_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'staff_dashboard_screen.dart';

/// The single entry point for the whole app. Wraps every public-facing
/// section — Home, Programs, TV and the Admin Portal — in one persistent
/// frame with a navigation rail (wide screens) or bottom bar (narrow), so
/// the user can move between pages without losing their place. Visitors
/// sign in from their phone by scanning the QR code on the Home screen.
class MainShell extends StatefulWidget {
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const _dayNames = [
    'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
  ];

  late int _index = widget.initialIndex;
  final _kiosk = KioskService();
  final _auth = AuthService();
  List<String> _tickerItems = [];

  // Tab indices, kept as names so the wiring stays readable.
  static const _kAdmin = 3;

  static const _destinations = <_Destination>[
    _Destination('Home', Icons.home_outlined, Icons.home),
    _Destination('Programs', Icons.event_note_outlined, Icons.event_note),
    _Destination('TV', Icons.live_tv_outlined, Icons.live_tv),
    _Destination(
        'Admin Portal', Icons.admin_panel_settings_outlined, Icons.admin_panel_settings),
  ];

  late final List<Widget> _pages = [
    const KioskHomeView(),
    const ProgramsView(),
    const TvChannelView(),
    const AdminPortalView(),
  ];

  @override
  void initState() {
    super.initState();
    _loadTicker();
  }

  Future<void> _loadTicker() async {
    try {
      final today = _dayNames[DateTime.now().weekday - 1];
      final programs = await _kiosk.getPrograms(day: today);
      programs.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
      if (!mounted) return;
      setState(() => _tickerItems = programs.map(_tickerLabel).toList());
    } catch (_) {
      // Ticker is decorative — ignore fetch failures.
    }
  }

  String _tickerLabel(Program program) {
    String label(String hhmm) {
      final parts = hhmm.split(':');
      final h = int.tryParse(parts[0]) ?? 0;
      final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      return DateFormat('h:mma').format(DateTime(2000, 1, 1, h, m)).toLowerCase();
    }

    final where =
        (program.location ?? '').isNotEmpty ? ' (${program.location})' : '';
    return '${program.title} · ${label(program.startTime)}–${label(program.endTime)}$where';
  }

  void _select(int i) {
    if (i != _index) setState(() => _index = i);
  }

  Widget _headerActions(bool wide) {
    final isClient = _auth.currentUser?.role == 'user';
    final isStaff = _isStaff;

    void openClient() => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) =>
              isClient ? const HomeScreen() : const ClientAccessScreen(),
        ));

    final clientIcon = isClient ? Icons.folder_shared : Icons.person;
    final clientLabel = isClient ? 'My Cases' : 'Client Access';
    final adminIcon =
        isStaff ? Icons.dashboard : Icons.admin_panel_settings;
    final adminLabel = isStaff ? 'Dashboard' : 'Staff Login';

    if (!wide) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: clientLabel,
            onPressed: openClient,
            icon: Icon(clientIcon, color: Colors.white, size: 20),
          ),
          IconButton(
            tooltip: adminLabel,
            onPressed: () => _select(_kAdmin),
            icon: Icon(adminIcon, color: Colors.white, size: 20),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton.icon(
          onPressed: openClient,
          icon: Icon(clientIcon, color: Colors.white, size: 18),
          label: Text(clientLabel,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 4),
        TextButton.icon(
          onPressed: () => _select(_kAdmin),
          icon: Icon(adminIcon, color: Colors.white, size: 18),
          label: Text(adminLabel,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  bool get _isStaff {
    final role = _auth.currentUser?.role;
    return role == 'admin' || role == 'secretary';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F6),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final pageArea = IndexedStack(index: _index, children: _pages);

            return Column(
              children: [
                KioskHeader(trailing: _headerActions(wide)),
                Expanded(
                  child: wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildRail(),
                            const VerticalDivider(
                                width: 1, color: Color(0x14000000)),
                            Expanded(child: pageArea),
                          ],
                        )
                      : pageArea,
                ),
                if (!wide) _buildBottomBar(),
                NewsTicker(items: _tickerItems),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRail() {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height - 200),
        child: IntrinsicHeight(
          child: NavigationRail(
            backgroundColor: const Color(0xFFFFFFFF),
            selectedIndex: _index,
            onDestinationSelected: _select,
            labelType: NavigationRailLabelType.all,
            groupAlignment: -0.9,
            selectedIconTheme: const IconThemeData(color: Color(0xFF2563EB)),
            selectedLabelTextStyle: const TextStyle(
                color: Color(0xFF2563EB), fontWeight: FontWeight.w700),
            unselectedIconTheme: const IconThemeData(color: Color(0xFF475569)),
            unselectedLabelTextStyle:
                const TextStyle(color: Color(0xFF475569)),
            destinations: [
              for (final d in _destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: Text(d.label, textAlign: TextAlign.center),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        backgroundColor: const Color(0xFFFFFFFF),
        indicatorColor: const Color(0xFF3b82f6).withOpacity(0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: states.contains(WidgetState.selected)
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF475569),
            )),
      ),
      child: NavigationBar(
        height: 64,
        selectedIndex: _index,
        onDestinationSelected: _select,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          for (final d in _destinations)
            NavigationDestination(
              icon: Icon(d.icon, color: const Color(0xFF475569)),
              selectedIcon: Icon(d.selectedIcon, color: const Color(0xFF2563EB)),
              label: d.label,
            ),
        ],
      ),
    );
  }
}

class _Destination {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  const _Destination(this.label, this.icon, this.selectedIcon);
}

/// Admin Portal tab: shows the staff sign-in form until a staff member is
/// authenticated, then swaps to the case dashboard. Both are embedded, so
/// they live inside the shell instead of pushing full-screen routes.
class AdminPortalView extends StatefulWidget {
  const AdminPortalView({super.key});

  @override
  State<AdminPortalView> createState() => _AdminPortalViewState();
}

class _AdminPortalViewState extends State<AdminPortalView> {
  final _auth = AuthService();

  bool get _isStaff {
    final role = _auth.currentUser?.role;
    return role == 'admin' || role == 'secretary';
  }

  @override
  Widget build(BuildContext context) {
    if (_isStaff) {
      return StaffDashboardScreen(
        embedded: true,
        onLoggedOut: () => setState(() {}),
      );
    }
    return LoginScreen(
      embedded: true,
      onSignedIn: () => setState(() {}),
    );
  }
}
