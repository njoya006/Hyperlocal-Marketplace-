import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App test harness renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('HyperLocal Test Harness'),
        ),
      ),
    );

    expect(find.text('HyperLocal Test Harness'), findsOneWidget);
  });
}
