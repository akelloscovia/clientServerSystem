// Basic smoke test: the app boots to the reception kiosk screen when no
// user session is stored, without throwing during the first frame.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:monitoring_client/main.dart';

void main() {
  testWidgets('App boots to the kiosk screen when logged out',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MonitoringClientApp(isLoggedIn: false));
    await tester.pump();

    expect(find.text('Ministry Reception'), findsOneWidget);
  });

  testWidgets('Split mode shows programs and TV side by side without overflow',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MonitoringClientApp(isLoggedIn: false));
    await tester.pump();

    await tester.tap(find.text('◨  Split'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Swap sides'), findsNothing); // tooltip, not a label
    expect(find.byIcon(Icons.swap_horiz), findsOneWidget);
  });
}
