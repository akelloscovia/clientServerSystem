import 'package:flutter/widgets.dart';

import 'web_channel_player_stub.dart'
    if (dart.library.html) 'web_channel_player_web.dart' as impl;

/// Embeds a TV channel's web player in an `<iframe>` when running on Flutter
/// web. On every other platform this is unused (the kiosk build plays these
/// channels through `webview_flutter` instead).
Widget buildEmbeddedChannel(String url) => impl.buildEmbeddedChannel(url);

/// Opens [url] in a new browser tab (web only).
void openChannelExternally(String url) => impl.openChannelExternally(url);
