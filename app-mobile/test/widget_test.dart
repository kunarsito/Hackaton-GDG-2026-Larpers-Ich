import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:faro_dev_app/main.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Sin sesión guardada se muestra el login', (tester) async {
    await tester.pumpWidget(const FaroDevCampusApp());
    await tester.pumpAndSettle();

    expect(find.text('Inicia sesión para continuar'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });

  testWidgets('Valida campos vacíos y cambia a registro', (tester) async {
    await tester.pumpWidget(const FaroDevCampusApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Entrar'));
    await tester.pump();
    expect(find.text('Escribe tu correo.'), findsOneWidget);
    expect(find.text('Escribe tu contraseña.'), findsOneWidget);

    await tester.tap(find.text('¿No tienes cuenta? Regístrate'));
    await tester.pump();
    expect(find.text('Crea tu cuenta'), findsOneWidget);
    expect(find.text('Nombre o usuario'), findsOneWidget);
  });

  testWidgets('Con sesión guardada sin servidor entra directo a la app', (tester) async {
    SharedPreferences.setMockInitialValues({
      'faro_auth_token': 'token-de-prueba',
      'faro_auth_user': '{"id":"usr-001","name":"Ada Dev","university":"FI","karmaPoints":420,"solvedChallenges":[]}',
    });
    await tester.pumpWidget(const FaroDevCampusApp());
    await tester.pumpAndSettle();

    expect(find.text('Inicia sesión para continuar'), findsNothing);
    expect(find.text('[KARMA: 420]'), findsOneWidget);
  });

  Future<void> openWithSession(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'faro_auth_token': 'token-de-prueba',
      'faro_auth_user':
          '{"id":"usr-001","name":"Ada Dev","university":"FI","karmaPoints":420,"solvedChallenges":[],"bio":"Me encantan los grafos","skills":["Dart"],"openToWork":true}',
    });
    await tester.pumpWidget(const FaroDevCampusApp());
    await tester.pumpAndSettle();
  }

  testWidgets('El perfil muestra Karma, biografía y habilidades (RF-15)', (tester) async {
    await openWithSession(tester);
    await tester.tap(find.text('PERFIL'));
    await tester.pumpAndSettle();

    expect(find.text('KARMA'), findsOneWidget);
    expect(find.text('Me encantan los grafos'), findsOneWidget);
    expect(find.text('Dart'), findsOneWidget);
    expect(find.text('ABIERTO A OPORTUNIDADES'), findsOneWidget);
    expect(find.text('EDITAR PERFIL'), findsOneWidget);
  });

  testWidgets('Comunidad ofrece Top, Recientes y Guardados (RF-11, RF-13)', (tester) async {
    await openWithSession(tester);
    await tester.tap(find.byIcon(Icons.forum_outlined));
    await tester.pumpAndSettle();

    expect(find.text('TOP'), findsOneWidget);
    expect(find.text('RECIENTES'), findsOneWidget);
    expect(find.text('GUARDADOS'), findsOneWidget);
  });

  testWidgets('En móvil (390 px) las 5 pestañas se dibujan sin desbordes (SRS §0)', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await openWithSession(tester);
    expect(find.byType(NavigationBar), findsOneWidget); // < 600 px: barra inferior
    for (final icon in [
      Icons.code_rounded,
      Icons.forum_outlined,
      Icons.work_outline_rounded,
      Icons.person_outline_rounded,
      Icons.auto_stories_outlined,
    ]) {
      await tester.tap(find.byIcon(icon).last);
      await tester.pumpAndSettle();
    }
    // Las pestañas de la Biblioteca también en móvil
    await tester.tap(find.text('CURSOS'));
    await tester.pumpAndSettle();
    expect(find.text('CREAR CURSO'), findsOneWidget);
  });

  testWidgets('Biblioteca y Práctica separan Oficial y Comunidad (SRS §1.1)', (tester) async {
    await openWithSession(tester);
    expect(find.text('OFICIAL'), findsWidgets);
    expect(find.text('COMUNIDAD'), findsWidgets);
    expect(find.text('CURSOS'), findsOneWidget);

    await tester.tap(find.text('PRÁCTICA'));
    await tester.pumpAndSettle();
    expect(find.text('CREAR RETO'), findsOneWidget);
  });
}
