import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:secret_santa/utils/app_navigation.dart';

void main() {
  Widget app(String initial) {
    final router = GoRouter(
      initialLocation: initial,
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(body: Text('HOME')),
        ),
        GoRoute(
          path: '/details',
          builder: (_, _) => BackScope(
            child: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => AppNavigation.back(context),
                  child: const Text('DETAILS'),
                ),
              ),
            ),
          ),
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  testWidgets('voltar sem página anterior vai para a Home', (tester) async {
    await tester.pumpWidget(app('/details'));
    await tester.tap(find.text('DETAILS'));
    await tester.pumpAndSettle();
    expect(find.text('HOME'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('voltar com página anterior faz pop', (tester) async {
    await tester.pumpWidget(app('/home'));
    final context = tester.element(find.text('HOME'));
    GoRouter.of(context).push('/details');
    await tester.pumpAndSettle();
    await tester.tap(find.text('DETAILS'));
    await tester.pumpAndSettle();
    expect(find.text('HOME'), findsOneWidget);
  });
}
