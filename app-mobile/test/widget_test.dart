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
      'faro_auth_user':
          '{"id":"usr-001","name":"Ada Dev","university":"FI","karmaPoints":420,"solvedChallenges":[]}',
    });
    await tester.pumpWidget(const FaroDevCampusApp());
    await tester.pumpAndSettle();

    expect(find.text('Inicia sesión para continuar'), findsNothing);
    expect(find.text('[KARMA: 420]'), findsOneWidget);
  });
}
