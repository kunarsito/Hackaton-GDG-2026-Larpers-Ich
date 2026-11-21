// Prueba de humo: la app arranca sin backend (fallback a datos semilla) y
// el Happy Path Biblioteca -> Práctica -> Foro funciona con Karma reactivo.
import 'dart:io';

import 'package:faro_dev_app/main.dart';
import 'package:faro_dev_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

  testWidgets('Happy Path offline en móvil', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const FaroDevCampusApp());
    await _settle(tester);

    // Móvil: barra inferior y artículos semilla.
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.textContaining('Edsger Dijkstra'), findsWidgets);
    final karmaBefore = ApiService().currentUser.karmaPoints;

    // 1-2. Artículo -> "Pon en práctica su legado".
    await tester.tap(find.text('LEER ARCHIVO >').first);
    await _settle(tester);
    final legacy = find.textContaining('PON EN PRÁCTICA SU LEGADO');
    await tester.scrollUntilVisible(legacy, 200, scrollable: find.byType(Scrollable).last);
    await tester.tap(legacy);
    await _settle(tester);

    // 3. Reto precargado con SymbolKeyboard (incluye comillas, exigidas por el SRS).
    expect(find.text('Ruta Mínima en una Matriz de Costos'), findsOneWidget);
    expect(find.text('"'), findsOneWidget);

    // 4. Falla la validación -> aparece "Pedir ayuda en el foro".
    await tester.scrollUntilVisible(find.byType(TextField), 200, scrollable: find.byType(Scrollable).first);
    await tester.enterText(find.byType(TextField), 'int calcular() {}');
    await tester.tap(find.textContaining('EJECUTAR PRUEBAS'));
    await _settle(tester);
    final help = find.textContaining('PEDIR AYUDA EN EL FORO');
    expect(help, findsOneWidget);

    // 5. Formulario del foro con título y código precargados; publicar da +10.
    await tester.ensureVisible(help);
    await tester.tap(help);
    await _settle(tester);
    expect(find.textContaining('Ayuda con solución para:'), findsOneWidget);
    expect(find.text('int calcular() {}'), findsOneWidget);
    final publish = find.textContaining('PUBLICAR EN LA COMUNIDAD');
    await tester.ensureVisible(publish);
    await tester.tap(publish);
    await _settle(tester);

    expect(ApiService().currentUser.karmaPoints, karmaBefore + 10);
    // El chip de la AppBar se actualiza sin cambiar de pestaña.
    expect(find.text('${karmaBefore + 10}K'), findsOneWidget);
    // El hilo queda vinculado al reto.
    expect(find.text('[RETO: ch-dijkstra-01]'), findsWidgets);

    // Volver a Comunidad desde la barra no reabre el formulario precargado.
    await tester.tap(find.text('EMPLEOS').last);
    await _settle(tester);
    await tester.tap(find.text('COMUNIDAD').last);
    await _settle(tester);
    expect(find.text('TÍTULO DEL HILO:'), findsNothing);
  });
}
