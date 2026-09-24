import 'dart:convert';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

/// Plays a short embedded tone so notifications do not depend on an external
/// asset URL or a separately deployed audio file.
class NotificationSoundService {
  static final NotificationSoundService _instance =
      NotificationSoundService._internal();
  factory NotificationSoundService() => _instance;
  NotificationSoundService._internal();

  static const _tone =
      'UklGRmQBAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YUABAACAgICAgICAgICAgICAgICAgICAgICtl3dbUFt3l62umnpdUFl0lKuunH1fUFdxkqqvn4BhUVZuj6mwoYNkUlVsjKewo4ZmUlNpiaWwpYlpU1JmhqOwp4xsVVJkg6GwqY9uVlFhgJ+vqpJxV1BffZyuq5R0WVBdepqurZd3W1Bbd5etrpp6XVBZdJSrrpx9X1BXcZKqr5+AYVFWbo+psKGDZFJVbIynsKOGZlJTaYmlsKWJaVNSZoajsKeMbFVSZIOhsKmPblZRYYCfr6qScVdQX32crquUdFlQXXqarq2Xd1tQW3eXra6ael1QWXSUq66cfV9QV3GSqq+fgGFRVm6PqbChg2RSVWyMp7CjhmZSU2mJpbCliWlTgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgA==';

  final AudioPlayer _player = AudioPlayer();
  late final Uint8List _bytes = base64Decode(_tone);

  Future<void> play() async {
    try {
      await _player.stop();
      await _player.play(BytesSource(_bytes), volume: 0.7);
    } catch (_) {
      // Browsers can reject audio until the user has interacted with the page.
    }
  }

  Future<void> dispose() => _player.dispose();
}
