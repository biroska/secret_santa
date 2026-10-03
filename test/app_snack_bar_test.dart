import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secret_santa/theme/app_colors.dart';
import 'package:secret_santa/widgets/app_snack_bar.dart';

void main() {
  Future<void> pumpAndShow(
    WidgetTester tester,
    void Function(BuildContext) show,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF123456)),
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => show(context),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Color bg(WidgetTester tester) => (tester
          .widget<Container>(
            find.ancestor(
              of: find.byIcon(Icons.close_rounded).evaluate().isNotEmpty
                  ? find.byIcon(Icons.close_rounded)
                  : find.byIcon(Icons.check_rounded),
              matching: find.byType(Container),
            ).first,
          )
          .decoration as BoxDecoration)
      .color!;

  testWidgets('erro: vermelho com ícone X', (tester) async {
    await pumpAndShow(tester, (c) => AppSnackBar.error(c, 'Falhou'));
    expect(find.text('Falhou'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(bg(tester), AppColors.snackError);
  });

  testWidgets('sucesso: cor do appBar com ícone check', (tester) async {
    await pumpAndShow(tester, (c) => AppSnackBar.success(c, 'Ok'));
    expect(find.text('Ok'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(bg(tester), const Color(0xFF123456));
  });
}
