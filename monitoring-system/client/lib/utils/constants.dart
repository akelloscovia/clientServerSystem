/// Application-wide constants.
class AppConstants {
  // Base URL — update this to your server IP/domain
  static const String baseUrl = 'http://10.0.2.2:5000/api'; // Android emulator
  // static const String baseUrl = 'http://localhost:5000/api'; // iOS / Web

  // Storage keys
  static const String tokenKey       = 'access_token';
  static const String refreshKey     = 'refresh_token';
  static const String userKey        = 'user_data';

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
    'pending':      'Pending',
    'under_review': 'Under Review',
    'assigned':     'Assigned',
    'resolved':     'Resolved',
    'closed':       'Closed',
  };
}
