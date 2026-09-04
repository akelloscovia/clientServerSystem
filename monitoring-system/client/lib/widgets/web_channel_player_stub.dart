import 'package:flutter/widgets.dart';

/// Non-web fallback — never actually shown, the kiosk build uses
/// `webview_flutter` for these channels.
Widget buildEmbeddedChannel(String url) => const SizedBox.shrink();

void openChannelExternally(String url) {}
