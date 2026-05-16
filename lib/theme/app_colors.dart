import 'package:flutter/material.dart';

/// Paleta e tokens de cor da app (tons de azul).
abstract final class AppColors {
  AppColors._();

  /// Base para [ColorScheme.fromSeed]: gera primários, superfícies e contentores M3.
  static const Color seed = Color(0xFF1565C0);

  /// Azul mais escuro para ênfase pontual (links, ícones destacados).
  static const Color accentDeep = Color(0xFF0D47A1);

  /// Fundo suave para gradientes ou áreas secundárias.
  static const Color surfaceTintBlue = Color(0xFFE8EEF7);
}
