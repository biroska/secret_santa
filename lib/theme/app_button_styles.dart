import 'package:flutter/material.dart';

/// Estilos de botão reutilizáveis. Cor, fonte e elevação vêm do tema padrão.
abstract final class AppButtonStyles {
  AppButtonStyles._();

  static const double height = 48;

  static const OutlinedBorder shape = StadiumBorder();

  static const Size minimumSize = Size(64, height);

  static ButtonStyle get elevated => ElevatedButton.styleFrom(
    minimumSize: minimumSize,
    shape: shape,
  );
}
