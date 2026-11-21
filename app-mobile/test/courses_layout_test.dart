// El botón "CREAR CURSO" no debe superponerse a los filtros en teléfonos pequeños.
import 'dart:io';

import 'package:faro_dev_app/core/theme/app_theme.dart';
import 'package:faro_dev_app/screens/courses_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoNetwork extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => throw const SocketException('offline (test)');
}

void main() {
  setUpAll(() => HttpOverrides.global = _NoNetwork());

  for (final width in [320.0, 360.0]) {
    for (final scale in [1.0, 1.3]) {
      testWidgets('CREAR CURSO no se superpone a los filtros [${width.toInt()}px, texto x$scale]', (tester) async {
        tester.view.physicalSize = Size(width, 640);
        tester.view.devicePixelRatio = 1.0;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(() {
          tester.view.reset();
          tester.platformDispatcher.clearTextScaleFactorTestValue();
        });

        await tester.pumpWidget(MaterialApp(
          theme: AppTheme.theme,
          home: const Scaffold(
            body: SingleChildScrollView(padding: EdgeInsets.all(16), child: CoursesView()),
          ),
        ));
        await tester.pump(const Duration(seconds: 2));

        final button = tester.getRect(find.text('CREAR CURSO'));
        final screen = Offset.zero & tester.view.physicalSize;
        expect(screen.contains(button.topLeft) && screen.contains(button.bottomRight), isTrue,
            reason: 'El botón debe verse completo en pantalla');

        for (final chip in tester.widgetList<ChoiceChip>(find.byType(ChoiceChip))) {
          final rect = tester.getRect(find.byWidget(chip));
          expect(rect.overlaps(button), isFalse,
              reason: 'El chip "${(chip.label as Text).data}" se superpone con CREAR CURSO');
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
}
