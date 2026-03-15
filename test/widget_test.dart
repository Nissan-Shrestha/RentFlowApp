import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rent_flow_app/main.dart';

void main() {
  testWidgets('App loads without errors', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const RentFlowApp());

    // Let the frame settle
    await tester.pumpAndSettle();

    // Just verify the app builds properly without any immediate crashes
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
