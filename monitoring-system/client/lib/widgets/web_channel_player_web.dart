// ignore_for_file: deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';

final Set<String> _registered = {};

/// Renders [url] inside an `<iframe>`. Many broadcaster pages send
/// `X-Frame-Options` / CSP `frame-ancestors` and will show blank inside the
/// frame — the caller pairs this with an "Open in new tab" action for that
/// case.
Widget buildEmbeddedChannel(String url) {
  final viewType = 'channel-iframe-${url.hashCode}';
  if (!_registered.contains(viewType)) {
    _registered.add(viewType);
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int _) {
      final iframe = html.IFrameElement()
        ..src = url
        ..style.border = '0'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allow = 'autoplay; encrypted-media; picture-in-picture; fullscreen'
        ..allowFullscreen = true;
      return iframe;
    });
  }
  return HtmlElementView(viewType: viewType);
}

void openChannelExternally(String url) {
  html.window.open(url, '_blank');
}
