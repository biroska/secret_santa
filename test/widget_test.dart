import 'package:flutter_test/flutter_test.dart';

import 'package:secret_santa/app/secret_santa_app.dart';

import 'fake_google_auth_api.dart';

void main() {
  testWidgets('Login screen shows Secret Santa and Google button',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      SecretSantaApp(auth: FakeGoogleAuthApi()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Secret Santa'), findsOneWidget);
    expect(find.text('Entrar com o Google'), findsOneWidget);
  });

  testWidgets('Tapping Google sign-in navigates to home with fake session',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      SecretSantaApp(auth: FakeGoogleAuthApi()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Entrar com o Google'));
    await tester.pumpAndSettle();

    expect(find.text('Você entrou'), findsOneWidget);
    expect(find.text('Test User'), findsOneWidget);
  });
}
