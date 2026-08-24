import 'package:flutter/foundation.dart';

/// Application-wide constants.
class AppConstants {
  static String get baseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000/api';
    }
    return 'http://localhost:5000/api';
  }

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
