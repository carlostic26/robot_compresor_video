import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:robot_compresor_video/features/home/presentation/tutorial_screen.dart';

void main() {
  testWidgets('Tutorial screen shows the basic and advanced sections', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: TutorialScreen()),
    );

    expect(find.text('Tutorial'), findsOneWidget);
    expect(find.text('Compresión básica'), findsWidgets);
    expect(find.text('Compresión avanzada'), findsWidgets);
  });
}
