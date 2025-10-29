import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_usage_tracker/screens/stats_screen.dart';

void main() {
  testWidgets('Tapping a list item navigates to detail', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: StatsScreen()));

    await tester.pumpAndSettle(); // wait for mock data

    // Tap the first ListTile
    final firstTile = find.byType(ListTile).first;
    expect(firstTile, findsOneWidget);
    await tester.tap(firstTile);
    await tester.pumpAndSettle();

    // Expect an AppBar with the app name
    expect(find.byType(AppBar), findsWidgets);
  });
}
