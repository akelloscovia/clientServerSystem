// Basic smoke tests for the logged-out entry screen.

import 'package:flutter_test/flutter_test.dart';

import 'package:monitoring_client/main.dart';

void main() {
  testWidgets('App boots into staff sign-in when logged out',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MonitoringClientApp(isLoggedIn: false));
    await tester.pump();

    expect(find.text('Ministry of Planning and Investment'), findsOneWidget);
    expect(find.text('SELECT PORTAL'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
    expect(find.text('Secretary'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Secretary portal can be selected without throwing',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MonitoringClientApp(isLoggedIn: false));
    await tester.pump();

    await tester.tap(find.text('Secretary'));
    await tester.pump();

    expect(find.text('Secretary workspace sign in'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
