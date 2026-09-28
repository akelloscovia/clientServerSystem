import 'dart:convert';

import 'package:pusher_client_socket/pusher_client_socket.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/constants.dart';
import 'auth_service.dart';
import 'notification_sound_service.dart';

/// Receives live notifications for the signed-in user over a private Pusher
/// channel. Notification rows remain persisted in the API as the fallback.
class NotificationRealtimeService {
  static final NotificationRealtimeService _instance =
      NotificationRealtimeService._internal();
  factory NotificationRealtimeService() => _instance;
  NotificationRealtimeService._internal();

  PusherClient? _client;
  Channel? _channel;
  Channel? _visitorChannel;
  int _unread = 0;
  int get unread => _unread;
  final List<void Function(Map<String, dynamic>)> _listeners = [];

  void addListener(void Function(Map<String, dynamic>) listener) {
    _listeners.add(listener);
  }

  void removeListener(void Function(Map<String, dynamic>) listener) {
    _listeners.remove(listener);
  }

  Future<void> connect() async {
    final user = AuthService().currentUser;
    if (user == null || AppConstants.pusherKey.isEmpty || _client != null) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final options = PusherOptions(
      key: AppConstants.pusherKey,
      cluster: AppConstants.pusherCluster,
      authOptions: PusherAuthOptions(
        '${AppConstants.baseUrl}/pusher/auth',
        headers: () async => {
          'Accept': 'application/json',
          'Authorization':
              'Bearer ${prefs.getString(AppConstants.tokenKey) ?? ''}',
        },
      ),
      autoConnect: false,
    );
    final client = PusherClient(options: options);
    _client = client;
    client.onConnectionError((error) {});
    client.connect();
    _channel = client.private('private-user-${user.id}');
    _channel!.bind('notification.created', (data) {
      final decoded = data is String ? jsonDecode(data) : data;
      if (decoded is! Map) return;
      final notification = decoded['notification'];
      if (notification is! Map<String, dynamic>) return;
      _unread++;
      NotificationSoundService().play();
      for (final listener in List.of(_listeners)) {
        listener(notification);
      }
    });

    _visitorChannel =
        client.channel<Channel>('visitor-updates', subscribe: true);
    _visitorChannel!.bind('visitor.updated', (data) {
      final decoded = data is String ? jsonDecode(data) : data;
      if (decoded is! Map) return;
      for (final listener in List.of(_listeners)) {
        listener(Map<String, dynamic>.from(decoded));
      }
    });
  }

  void disconnect() {
    _channel?.unsubscribe();
    _visitorChannel?.unsubscribe();
    _client?.disconnect();
    _channel = null;
    _visitorChannel = null;
    _client = null;
    _unread = 0;
  }
}
