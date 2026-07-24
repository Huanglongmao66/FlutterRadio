import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:online_fm_radio/core/ui/main_app.dart';

void main() {
  testWidgets('App renders smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: MainApp()));
    expect(find.byType(MainApp), findsOneWidget);
  });
}
