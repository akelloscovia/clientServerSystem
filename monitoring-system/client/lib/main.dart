import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set status bar to transparent
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0a0d14),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final authService = AuthService();
  final user = await authService.restoreSession();

  runApp(MonitoringClientApp(isLoggedIn: user != null));
}

class MonitoringClientApp extends StatelessWidget {
  final bool isLoggedIn;

  const MonitoringClientApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MonitorSys Client',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0a0d14),
        primaryColor: const Color(0xFF3b82f6),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3b82f6),
          secondary: Color(0xFF60a5fa),
          surface: Color(0xFF111827),
          background: Color(0xFF0a0d14),
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0d1117),
          elevation: 0,
          centerTitle: false,
        ),
      ),
      // The app opens on the login screen; signing in leads to the home
      // page (MainShell). A restored session skips the login screen — a
      // client lands on their own case list, staff on the home page (the
      // Admin Portal tab there shows the dashboard).
      home: !isLoggedIn
          ? const LoginScreen()
          : AuthService().currentUser?.role == 'user'
              ? const HomeScreen()
              : const MainShell(),
    );
  }
}
