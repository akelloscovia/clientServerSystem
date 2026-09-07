import 'package:flutter/foundation.dart';

/// Application-wide constants.
class AppConstants {
  static String get baseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000/api';
    }
    return 'http://localhost:5000/api';
  }

  /// Base URL of the web dashboard (React), used to build the visitor
  /// sign-in link shown as a QR code on the reception kiosk.
  static String get webPortalBaseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5173';
    }
    return 'http://localhost:5173';
  }

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
