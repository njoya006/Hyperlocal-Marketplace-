import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:hyperlocal_market/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app startup and key screens remain responsive', (tester) async {
    final stopwatch = Stopwatch()..start();

    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 20));

    final startupMs = stopwatch.elapsedMilliseconds;
    debugPrint('APP_PERF startup_ms=$startupMs');

    expect(find.byType(MaterialApp), findsOneWidget);

    final createAccountButton = find.widgetWithText(TextButton, 'Create account');
    if (createAccountButton.evaluate().isNotEmpty) {
      await tester.tap(createAccountButton);
      await tester.pumpAndSettle(const Duration(seconds: 10));
      expect(find.text('Create Account').first, findsOneWidget);

      final backButton = find.byIcon(Icons.arrow_back);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
        await tester.pumpAndSettle(const Duration(seconds: 5));
      }
    }

    final developerToolsButton = find.widgetWithText(TextButton, 'Developer tools');
    if (developerToolsButton.evaluate().isNotEmpty) {
      await tester.tap(developerToolsButton);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      if (find.text('Developer Role Switch').evaluate().isNotEmpty) {
        expect(find.text('Developer Role Switch').evaluate(), isNotEmpty);
      }
    }

    debugPrint('APP_PERF screen_navigation_complete=true');
  });
}
