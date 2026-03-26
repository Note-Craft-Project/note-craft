// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:notecraft/main.dart';

void main() {
  testWidgets('NoteCraft smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const NoteCraftApp());

    // Verify that the title Note Craft is present.
    expect(find.text('Note Craft'), findsOneWidget);
    
    // Verify that the navigation items are present.
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Leaderboard'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}
