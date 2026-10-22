import 'package:flutter/material.dart';

/// Estilos de botão reutilizáveis. Cor, fonte e elevação vêm do tema padrão.
abstract final class AppButtonStyles {
  AppButtonStyles._();

  static const double height = 48;

  static const OutlinedBorder shape = StadiumBorder();

  static const Size minimumSize = Size(64, height);

  static ButtonStyle get elevated =>
      ElevatedButton.styleFrom(minimumSize: minimumSize, shape: shape);
}

/// Estilos de card reutilizáveis. Cor, elevação e forma vêm do `cardTheme`.
abstract final class AppCardStyles {
  AppCardStyles._();

  static const double radius = 12;

  static const EdgeInsets padding = EdgeInsets.all(14);

  static const EdgeInsets compactPadding = EdgeInsets.all(10);

  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 10,
  );
}
