import 'package:flutter/foundation.dart';

/// Application-wide constants.
class AppConstants {
  static String get baseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000/api';
    }
    return 'http://localhost:5000/api';
  }

  /// Base URL of the web dashboard (React / Vite) that hosts the public
  /// visitor sign-in form. This is the address a visitor's phone must be
  /// able to reach when it scans the **printed** reception QR code, so set
  /// it to the deployment's real host — a LAN IP (e.g.
  /// `http://192.168.1.108:5173`) or a public hostname, never `localhost`.
  static const String webPortalBaseUrl =
      String.fromEnvironment('WEB_PORTAL_URL', defaultValue: 'http://localhost:5173');

  /// Public visitor sign-in form (no login required). Encode this URL in
  /// the QR code that is printed and displayed at the reception desk.
  static String get visitorFormUrl => '$webPortalBaseUrl/visitor-form';

  // Kiosk branding
  static const String orgName = 'Ministry of Planning and Investment';
  static const String orgTag = 'MINISTRY';

  // Storage keys
  static const String tokenKey = 'access_token';
  static const String refreshKey = 'refresh_token';
  static const String userKey = 'user_data';

  // Submission categories
  static const List<String> categories = [
    'complaint',
    'inquiry',
    'report',
    'request',
    'other',
  ];

  // Submission priorities
  static const List<String> priorities = [
    'low',
    'medium',
    'high',
    'urgent',
  ];

  // Status labels
  static const Map<String, String> statusLabels = {
    'pending': 'Pending',
    'under_review': 'Under Review',
    'assigned': 'Assigned',
    'resolved': 'Resolved',
    'closed': 'Closed',
  };
}
