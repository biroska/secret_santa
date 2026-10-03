import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';

/// Navegação "voltar" centralizada. Nunca remove a última página do
/// go_router: quando não há para onde voltar, vai para o pai da rota atual.
class AppNavigation {
  AppNavigation._();

  /// Pai lógico das rotas, usado quando a pilha só tem a página atual
  /// (reload na web, deep link ou navegação por `go`). Todas as telas
  /// alcançáveis por `go` têm a Home como pai.
  static String fallbackParent(String location) => AppRoutes.HOME;

  static bool canGoBack(BuildContext context) =>
      Navigator.of(context).canPop();

  static void back(BuildContext context, [Object? result]) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop(result);
      return;
    }
    goToFallback(context);
  }

  static void goToFallback(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    if (router == null) return;
    final location = router.routeInformationProvider.value.uri.toString();
    if (location == AppRoutes.HOME) return;
    router.go(fallbackParent(location));
  }
}

/// Faz o botão voltar do sistema/navegador usar o mesmo fallback do AppBar.
class BackScope extends StatelessWidget {
  const BackScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: AppNavigation.canGoBack(context),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) AppNavigation.goToFallback(context);
      },
      child: child,
    );
  }
}
