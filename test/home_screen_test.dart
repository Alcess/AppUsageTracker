import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_usage_tracker/screens/stats_screen.dart';

void main() {
  testWidgets('HomeScreen builds and shows title', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: StatsScreen()));

    expect(find.text('App Usage Tracker'), findsOneWidget);
    // Tabs/buttons
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Week'), findsOneWidget);
    expect(find.text('Month'), findsOneWidget);

    // Wait for mocked data to load
    await tester.pumpAndSettle();

    // Should show list items or summary
    expect(find.byType(ListTile), findsWidgets);
  });
}
