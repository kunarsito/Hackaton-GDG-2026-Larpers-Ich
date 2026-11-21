// Happy Path del SRS (§6) en móvil, sin backend (fallback a datos semilla):
// Biblioteca -> "Pon en práctica su legado" -> reto con SymbolKeyboard ->
// fallo -> "Pedir ayuda en el foro" -> formulario precargado vinculado al reto.
import 'dart:io';

import 'package:faro_dev_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoNetwork extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      throw const SocketException('offline (test)');
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 800));
  }
}

void main() {
  setUpAll(() => HttpOverrides.global = _NoNetwork());

  testWidgets('Happy Path offline en móvil (SRS §6)', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({
      'faro_auth_token': 'token-de-prueba',
      'faro_auth_user':
          '{"id":"usr-001","name":"Ada Dev","university":"FI","karmaPoints":420,"solvedChallenges":[]}',
    });

    await tester.pumpWidget(const FaroDevCampusApp());
    await _settle(tester);
    expect(find.byType(NavigationBar), findsOneWidget);

    // 1-2. Artículo -> "Pon en práctica su legado".
    final read = find.text('LEER ARCHIVO >').first;
    await tester.ensureVisible(read);
    await tester.tap(read);
    await _settle(tester);
    final legacy = find.textContaining('PON EN PRÁCTICA SU LEGADO');
    await tester.scrollUntilVisible(legacy, 200, scrollable: find.byType(Scrollable).last);
    await tester.tap(legacy);
    await _settle(tester);

    // 3. Reto precargado con SymbolKeyboard (el SRS exige la tecla de comillas).
    expect(find.text('Ruta Mínima en una Matriz de Costos'), findsOneWidget);
    expect(find.text('"'), findsOneWidget);

    // 4. Falla la validación -> aparece "Pedir ayuda en el foro".
    await tester.scrollUntilVisible(find.byType(TextField), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.enterText(find.byType(TextField), 'int calcular() {}');
    await tester.tap(find.textContaining('EJECUTAR PRUEBAS'));
    await _settle(tester);
    final help = find.textContaining('PEDIR AYUDA EN EL FORO');
    expect(help, findsOneWidget);

    // 5. Formulario del foro con título y código precargados.
    await tester.ensureVisible(help);
    await tester.tap(help);
    await _settle(tester);
    expect(find.textContaining('Ayuda con solución para:'), findsOneWidget);
    expect(find.text('int calcular() {}'), findsOneWidget);

    // Cerrar el formulario y volver a Comunidad desde la barra no lo reabre.
    Navigator.of(tester.element(find.text('TÍTULO:'))).pop();
    await _settle(tester);
    await tester.tap(find.text('EMPLEOS').last);
    await _settle(tester);
    await tester.tap(find.text('COMUNIDAD').last);
    await _settle(tester);
    expect(find.text('TÍTULO:'), findsNothing);
  });
}
