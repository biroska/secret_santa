import 'package:flutter/material.dart';

import '../app/app_keys.dart';
import '../theme/app_colors.dart';

enum AppSnackType { success, error }

/// Único ponto de exibição de SnackBars do app. Não use `showSnackBar`
/// diretamente nas telas.
abstract final class AppSnackBar {
  AppSnackBar._();

  static void success(BuildContext context, String message) =>
      showOn(ScaffoldMessenger.of(context), AppSnackType.success, message);

  static void error(BuildContext context, String message) =>
      showOn(ScaffoldMessenger.of(context), AppSnackType.error, message);

  /// Variantes para um messenger capturado antes de um `await`.
  static void successOn(ScaffoldMessengerState? messenger, String message) =>
      showOn(messenger, AppSnackType.success, message);

  static void errorOn(ScaffoldMessengerState? messenger, String message) =>
      showOn(messenger, AppSnackType.error, message);

  /// Variantes que usam o messenger global (útil após trocar de rota).
  static void successRoot(String message) => showOn(
    rootScaffoldMessengerKey.currentState,
    AppSnackType.success,
    message,
  );

  static void errorRoot(String message) => showOn(
    rootScaffoldMessengerKey.currentState,
    AppSnackType.error,
    message,
  );

  static void showOn(
    ScaffoldMessengerState? messenger,
    AppSnackType type,
    String message,
  ) {
    if (messenger == null) return;
    final theme = Theme.of(messenger.context);
    final isError = type == AppSnackType.error;
    final background = isError
        ? AppColors.snackError
        : (theme.appBarTheme.backgroundColor ?? theme.colorScheme.primary);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          padding: EdgeInsets.zero,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          duration: Duration(seconds: isError ? 4 : 3),
          content: Semantics(
            liveRegion: true,
            child: _AppSnackContent(
              message: message,
              icon: isError ? Icons.close_rounded : Icons.check_rounded,
              background: background,
            ),
          ),
        ),
      );
  }
}

class _AppSnackContent extends StatelessWidget {
  const _AppSnackContent({
    required this.message,
    required this.icon,
    required this.background,
  });

  final String message;
  final IconData icon;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 20, 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
