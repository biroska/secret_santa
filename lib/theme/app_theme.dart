import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Temas claros/escuros derivados da paleta em [AppColors].
abstract final class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: Brightness.light,
      surface: AppColors.surfaceTintBlue,
    );
    return _baseTheme(scheme);
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: Brightness.dark,
    );
    return _baseTheme(scheme);
  }

  static ThemeData _baseTheme(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: scheme.inversePrimary,
        foregroundColor: scheme.onSurface,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
    );
  }
}
