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
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFEEF2F6),
      systemNavigationBarIconBrightness: Brightness.dark,
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
      title: 'Ministry of Planning and Investment',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFEEF2F6),
        primaryColor: const Color(0xFF3b82f6),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF3b82f6),
          secondary: Color(0xFF2563EB),
          surface: Color(0xFFFFFFFF),
          background: Color(0xFFEEF2F6),
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFFFFF),
          foregroundColor: Color(0xFF0F172A),
          elevation: 0,
          centerTitle: false,
        ),
        dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
        datePickerTheme: const DatePickerThemeData(backgroundColor: Colors.white),
        timePickerTheme: const TimePickerThemeData(backgroundColor: Colors.white),
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
