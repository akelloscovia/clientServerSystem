import 'package:flutter/foundation.dart';

/// True while a dialog/overlay (e.g. visitor sign-in) is showing on top of
/// the kiosk. Platform views like the TV channel `<iframe>` are real DOM
/// elements that intercept clicks landing in their rectangle regardless of
/// what Flutter widget is painted on top of them — Flutter's own canvas
/// content has `pointer-events: none` and can't occlude them by itself. Any
/// widget that hosts a platform view should watch this and ignore pointer
/// input while it's true.
final ValueNotifier<bool> overlayOpen = ValueNotifier<bool>(false);
