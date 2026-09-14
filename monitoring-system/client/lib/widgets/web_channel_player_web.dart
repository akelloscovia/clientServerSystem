// ignore_for_file: deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import '../services/overlay_state.dart';

final Set<String> _registered = {};
final List<html.IFrameElement> _iframes = [];
bool _overlayListenerAdded = false;

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
        ..style.pointerEvents = overlayOpen.value ? 'none' : 'auto'
        ..allow = 'autoplay; encrypted-media; picture-in-picture; fullscreen'
        ..allowFullscreen = true;
      _iframes.add(iframe);
      return iframe;
    });
  }
  if (!_overlayListenerAdded) {
    _overlayListenerAdded = true;
    // The iframe is a real DOM element sitting outside Flutter's own
    // hit-testing (IgnorePointer only skips Flutter's hit-test, it doesn't
    // touch the iframe's native pointer-events) — it swallows clicks meant
    // for anything Flutter draws on top of it, like a dialog, unless the
    // DOM element itself is told to stop capturing pointer input.
    overlayOpen.addListener(() {
      final blocked = overlayOpen.value;
      for (final iframe in _iframes) {
        iframe.style.pointerEvents = blocked ? 'none' : 'auto';
      }
    });
  }
  return HtmlElementView(viewType: viewType);
}

void openChannelExternally(String url) {
  html.window.open(url, '_blank');
}
