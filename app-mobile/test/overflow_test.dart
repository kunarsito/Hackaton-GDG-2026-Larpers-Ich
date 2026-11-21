// Pruebas de regresión de overflow en layouts móviles.
//
// Renderiza cada pantalla en tamaños de teléfono reales, con escala de texto
// aumentada y con el teclado en pantalla abierto, y falla si algún RenderFlex
// se desborda ("BOTTOM/RIGHT OVERFLOWED BY ...").
//
// La fuente por defecto de flutter_test dibuja cada glifo como un cuadrado de
// 1em, mucho más ancho que una fuente monoespaciada real (~0.6em). Si existe,
// se carga Courier New (misma métrica que Droid Sans Mono) para medir como en
// un dispositivo; si no, la prueba sigue funcionando pero es más pesimista.
import 'dart:io';

import 'package:faro_dev_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _loadFont(String family, List<String> paths) async {
  for (final p in paths) {
    final f = File(p);
    if (f.existsSync()) {
      final loader = FontLoader(family)
        ..addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
      await loader.load();
      return;
    }
  }
}

const _phones = <String, Size>{
  'small-320x568': Size(320, 568),
  'medium-360x640': Size(360, 640),
};

const _keyboardHeight = 280.0;

void Function() _restoreOnError = () {};

/// Captura los errores de overflow en lugar de abortar en el primero.
List<String> _captureOverflows() {
  final overflows = <String>[];
  final original = FlutterError.onError;
  _restoreOnError = () => FlutterError.onError = original;
  FlutterError.onError = (details) {
    final msg = details.exceptionAsString();
    if (msg.contains('overflowed')) {
      overflows.add(msg.split('\n').first);
    } else {
      original?.call(details);
    }
  };
  return overflows;
}

/// Sin red: fuerza el fallback a datos semilla de ApiService (determinista).
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

Future<void> _pumpApp(WidgetTester tester, Size size, double textScale) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  await tester.pumpWidget(const FaroDevCampusApp());
  await _settle(tester);
}

void _resetView(WidgetTester tester) {
  _restoreOnError();
  tester.view.reset();
  tester.platformDispatcher.clearTextScaleFactorTestValue();
}

Future<void> _openTab(WidgetTester tester, String label) async {
  await tester.tap(find.text(label).last);
  await _settle(tester);
}

Future<void> _openKeyboard(WidgetTester tester) async {
  tester.view.viewInsets = const FakeViewPadding(bottom: _keyboardHeight);
  await tester.pump(const Duration(milliseconds: 500));
}

/// Recorre el árbol de render y describe cada Row/Column cuyo contenido no
/// cabe en su tamaño, con los primeros textos que contiene para ubicarlo.
Set<String> _overflowingFlexes(WidgetTester tester) {
  final found = <String>{};
  for (final ro in tester.allRenderObjects) {
    if (ro is! RenderFlex || !ro.hasSize) continue;
    final horizontal = ro.direction == Axis.horizontal;
    var extent = 0.0;
    ro.visitChildren((c) {
      final box = c as RenderBox;
      if (box.hasSize) extent += horizontal ? box.size.width : box.size.height;
    });
    final available = horizontal ? ro.size.width : ro.size.height;
    final excess = extent - available;
    if (excess <= 0.5) continue;
    final texts = <String>[];
    void collect(RenderObject o) {
      if (texts.length >= 3) return;
      if (o is RenderParagraph) {
        final t = o.text.toPlainText().replaceAll('\n', ' ');
        texts.add(t.length > 40 ? '${t.substring(0, 40)}…' : t);
      }
      o.visitChildren(collect);
    }
    collect(ro);
    found.add('${horizontal ? 'Row' : 'Column'} +${excess.toStringAsFixed(1)}px ${texts.isEmpty ? '(sin texto)' : texts}');
  }
  return found;
}

Future<void> _scrollThrough(WidgetTester tester, Finder scrollable, Set<String> out) async {
  for (var i = 0; i < 14; i++) {
    await tester.drag(scrollable, const Offset(0, -220), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 200));
    out.addAll(_overflowingFlexes(tester));
  }
}

void main() {
  setUpAll(() async {
    HttpOverrides.global = _NoNetwork();
    await _loadFont('monospace', [r'C:\Windows\Fonts\cour.ttf', '/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf']);
    await _loadFont('sans-serif', [r'C:\Windows\Fonts\arial.ttf', '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf']);
  });

  for (final phone in _phones.entries) {
    for (final scale in [1.0, 1.3]) {
      final tag = '${phone.key} @ text x$scale';

      testWidgets('tabs principales sin overflow [$tag]', (tester) async {
        final overflows = _captureOverflows();
        final where = <String>{};
        await _pumpApp(tester, phone.value, scale);
        for (final tab in ['BIBLIOTECA', 'PRÁCTICA', 'COMUNIDAD', 'EMPLEOS']) {
          await _openTab(tester, tab);
          where.addAll(_overflowingFlexes(tester));
          await _scrollThrough(tester, find.byType(Scrollable).first, where);
        }
        _resetView(tester);
        expect(overflows, isEmpty, reason: where.join('\n'));
      });

      testWidgets('modal de artículo sin overflow [$tag]', (tester) async {
        final overflows = _captureOverflows();
        final where = <String>{};
        await _pumpApp(tester, phone.value, scale);
        final read = find.text('LEER ARCHIVO >').first;
        await tester.ensureVisible(read);
        await tester.pump();
        await tester.tap(read);
        await _settle(tester);
        expect(find.textContaining('PIONERO/A:'), findsOneWidget);
        where.addAll(_overflowingFlexes(tester));
        await _scrollThrough(tester, find.byType(Scrollable).last, where);
        _resetView(tester);
        expect(overflows, isEmpty, reason: where.join('\n'));
      });

      testWidgets('reto: fallo + teclado abierto sin overflow [$tag]', (tester) async {
        final overflows = _captureOverflows();
        final where = <String>{};
        await _pumpApp(tester, phone.value, scale);
        await _openTab(tester, 'PRÁCTICA');
        final open = find.text('Ruta Mínima en una Matriz de Costos');
        await tester.scrollUntilVisible(open, 200, scrollable: find.byType(Scrollable).first);
        await tester.ensureVisible(open);
        await tester.pump();
        await tester.tap(open);
        await _settle(tester);
        expect(find.textContaining('EJECUCIÓN //'), findsOneWidget);

        // Código que no pasa la validación (fallback offline) para mostrar
        // el resultado de error y el botón "Pedir ayuda en el foro".
        final editor = find.byType(TextField);
        await tester.scrollUntilVisible(editor, 200, scrollable: find.byType(Scrollable).first);
        await tester.enterText(editor, 'int calcular() {}');
        final run = find.textContaining('EJECUTAR PRUEBAS');
        await tester.ensureVisible(run);
        await tester.tap(run);
        await _settle(tester);
        expect(find.textContaining('PEDIR AYUDA EN EL FORO'), findsOneWidget);
        where.addAll(_overflowingFlexes(tester));

        await tester.showKeyboard(editor);
        await _openKeyboard(tester);
        where.addAll(_overflowingFlexes(tester));
        _resetView(tester);
        await tester.pump();
        expect(overflows, isEmpty, reason: where.join('\n'));
      });

      testWidgets('foro: nuevo hilo y respuestas con teclado sin overflow [$tag]', (tester) async {
        final overflows = _captureOverflows();
        final where = <String>{};
        await _pumpApp(tester, phone.value, scale);
        await _openTab(tester, 'COMUNIDAD');

        await tester.tap(find.text('CREAR HILO'));
        await _settle(tester);
        expect(find.text('TÍTULO DEL HILO:'), findsOneWidget);
        where.addAll(_overflowingFlexes(tester));
        await _openKeyboard(tester);
        where.addAll(_overflowingFlexes(tester));
        tester.view.resetViewInsets();
        await tester.pump(const Duration(milliseconds: 300));
        Navigator.of(tester.element(find.text('TÍTULO DEL HILO:'))).pop();
        await _settle(tester);

        final replies = find.ancestor(
          of: find.textContaining('RESPUESTAS (').first,
          matching: find.byType(OutlinedButton),
        );
        await tester.scrollUntilVisible(replies, 200, scrollable: find.byType(Scrollable).first);
        await tester.ensureVisible(replies);
        await tester.pump();
        await tester.tap(replies);
        await _settle(tester);
        expect(find.textContaining('HILO // '), findsOneWidget);
        where.addAll(_overflowingFlexes(tester));
        await _openKeyboard(tester);
        where.addAll(_overflowingFlexes(tester));
        _resetView(tester);
        await tester.pump();
        expect(overflows, isEmpty, reason: where.join('\n'));
      });
    }
  }
}
