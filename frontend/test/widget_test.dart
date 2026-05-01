import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:paw/config/theme.dart';

void main() {
  testWidgets('PAW theme renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: Center(child: Text('PAW')),
        ),
      ),
    );

    expect(find.text('PAW'), findsOneWidget);
  });
}
