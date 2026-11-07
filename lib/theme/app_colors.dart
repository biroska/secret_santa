import 'package:flutter/material.dart';

/// Semantic colors that complement Material's [ColorScheme].
final class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.infoContainer,
    required this.onInfoContainer,
    required this.giftContainer,
    required this.onGiftContainer,
  });

  static const Color seed = Color(0xFF1565C0);

  static const AppColors light = AppColors(
    successContainer: Color(0xFFEAF5EC),
    onSuccessContainer: Color(0xFF256B3B),
    warningContainer: Color(0xFFFFF3D9),
    onWarningContainer: Color(0xFF805600),
    infoContainer: Color(0xFFE9F3FA),
    onInfoContainer: Color(0xFF245B80),
    giftContainer: Color(0xFFFFF1D6),
    onGiftContainer: Color(0xFF805500),
  );

  static const AppColors dark = AppColors(
    successContainer: Color(0xFF183B28),
    onSuccessContainer: Color(0xFFB5E4C1),
    warningContainer: Color(0xFF49370F),
    onWarningContainer: Color(0xFFF4D58A),
    infoContainer: Color(0xFF183649),
    onInfoContainer: Color(0xFFB8DDF3),
    giftContainer: Color(0xFF49320B),
    onGiftContainer: Color(0xFFFFD98A),
  );

  final Color successContainer;
  final Color onSuccessContainer;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color infoContainer;
  final Color onInfoContainer;
  final Color giftContainer;
  final Color onGiftContainer;

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>() ??
      (Theme.of(context).brightness == Brightness.dark ? dark : light);

  @override
  AppColors copyWith({
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? infoContainer,
    Color? onInfoContainer,
    Color? giftContainer,
    Color? onGiftContainer,
  }) {
    return AppColors(
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      infoContainer: infoContainer ?? this.infoContainer,
      onInfoContainer: onInfoContainer ?? this.onInfoContainer,
      giftContainer: giftContainer ?? this.giftContainer,
      onGiftContainer: onGiftContainer ?? this.onGiftContainer,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;

    return AppColors(
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      onSuccessContainer: Color.lerp(
        onSuccessContainer,
        other.onSuccessContainer,
        t,
      )!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      onWarningContainer: Color.lerp(
        onWarningContainer,
        other.onWarningContainer,
        t,
      )!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      onInfoContainer: Color.lerp(onInfoContainer, other.onInfoContainer, t)!,
      giftContainer: Color.lerp(giftContainer, other.giftContainer, t)!,
      onGiftContainer: Color.lerp(onGiftContainer, other.onGiftContainer, t)!,
    );
  }
}
