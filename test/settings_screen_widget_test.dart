import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_usage_tracker/screens/settings_screen.dart';
import 'package:app_usage_tracker/utils/app_theme.dart';

void main() {
  testWidgets('Settings subtitles and dropdown items are readable in dark mode', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const SettingsScreen(),
    ));

    await tester.pumpAndSettle();

    // Verify subtitle style color for the dark-mode subtitle is the expected onSurface with alpha 0.7
    final subtitleFinder = find.text('Use dark theme (changes immediately)');
    expect(subtitleFinder, findsOneWidget);
    final Text subtitleText = tester.widget<Text>(subtitleFinder);
    final expectedSubtitleColor = AppTheme.darkTheme.colorScheme.onSurface.withValues(alpha: 0.7);
    expect(subtitleText.style?.color, expectedSubtitleColor);

    // Open the dropdown and ensure menu items use onSurface color
    final dropdownFinder = find.byType(DropdownButton<TimeRange>);
    expect(dropdownFinder, findsOneWidget);

    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();

    final todayTexts = tester.widgetList<Text>(find.text('Today')).toList();
    // There should be at least one 'Today' in the opened menu; ensure one of them uses the expected color
    final expectedItemColor = AppTheme.darkTheme.colorScheme.onSurface;
    final hasExpected = todayTexts.any((t) => t.style?.color == expectedItemColor);
    expect(hasExpected, isTrue, reason: 'At least one dropdown menu item should use onSurface color in dark mode');
  });
}
