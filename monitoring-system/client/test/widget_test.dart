// Basic smoke tests: the app boots into the unified MainShell when no user
// session is stored, and the nav lets you move between the four sections
// without throwing during the first frame.

import 'package:flutter_test/flutter_test.dart';

import 'package:monitoring_client/main.dart';

void main() {
  testWidgets('App boots into the main shell when logged out',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MonitoringClientApp(isLoggedIn: false));
    await tester.pump();

    // Every nav destination is present.
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Programs'), findsWidgets);
    expect(find.text('TV'), findsWidgets);
    expect(find.text('Visitor Sign-In'), findsWidgets);
    expect(find.text('Admin Portal'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Admin Portal tab shows the staff sign-in form',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MonitoringClientApp(isLoggedIn: false));
    await tester.pump();

    await tester.tap(find.text('Admin Portal').last);
    await tester.pump();

    expect(find.text('SELECT PORTAL'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}














