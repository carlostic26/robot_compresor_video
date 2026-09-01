import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:robot_compresor_video/main.dart';

void main() {
  testWidgets('La pantalla de carga muestra el placeholder y el botón', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const App());
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Robot'), findsOneWidget);
    expect(find.text('Compresor de Video'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Continuar'), findsOneWidget);
  });
}
