import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secret_santa/theme/app_colors.dart';
import 'package:secret_santa/theme/app_theme.dart';

void main() {
  test(
    'light and dark themes provide distinct surfaces and semantic colors',
    () {
      final lightTheme = AppTheme.light;
      final darkTheme = AppTheme.dark;
      final lightColors = lightTheme.extension<AppColors>()!;
      final darkColors = darkTheme.extension<AppColors>()!;

      expect(lightTheme.brightness, Brightness.light);
      expect(darkTheme.brightness, Brightness.dark);
      expect(
        lightTheme.scaffoldBackgroundColor,
        isNot(darkTheme.scaffoldBackgroundColor),
      );
      expect(lightTheme.cardTheme.color, isNot(darkTheme.cardTheme.color));
      expect(lightColors.successContainer, isNot(darkColors.successContainer));
      expect(lightTheme.cardTheme.surfaceTintColor, Colors.transparent);
      expect(darkTheme.cardTheme.surfaceTintColor, Colors.transparent);
    },
  );
}
