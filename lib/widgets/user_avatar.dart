import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Avatar circular com cache em disco/memória da foto de perfil.
/// Se a imagem não estiver no cache, é baixada da URL, salva e exibida.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.photoUrl,
    this.radius = 20,
    this.cacheKey,
    this.fallbackBuilder,
    this.backgroundColor,
  });

  final String? photoUrl;
  final double radius;
  final String? cacheKey;
  final Widget Function()? fallbackBuilder;
  final Color? backgroundColor;

  // Remove o sufixo de tamanho do Google (ex.: =s96-c) para uma chave estável.
  static String _stableKey(String url) =>
      url.replaceFirst(RegExp(r'=s\d+(-c)?$'), '');

  Widget _fallback(Color backgroundColor, Color iconColor) =>
      fallbackBuilder?.call() ??
      Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.person, color: iconColor, size: radius * 1.1),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarBackground =
        backgroundColor ?? theme.colorScheme.surfaceContainerHighest;
    final url = photoUrl?.trim() ?? '';
    if (url.isEmpty) {
      return _fallback(avatarBackground, theme.colorScheme.onSurfaceVariant);
    }

    final px = (radius * 2 * MediaQuery.devicePixelRatioOf(context)).round();

    return CachedNetworkImage(
      imageUrl: url,
      cacheKey: cacheKey ?? _stableKey(url),
      memCacheWidth: px,
      memCacheHeight: px,
      fadeInDuration: const Duration(milliseconds: 150),
      imageBuilder: (context, provider) => CircleAvatar(
        radius: radius,
        backgroundImage: provider,
        backgroundColor: avatarBackground,
      ),
      placeholder: (context, _) =>
          CircleAvatar(radius: radius, backgroundColor: avatarBackground),
      errorWidget: (context, _, _) =>
          _fallback(avatarBackground, theme.colorScheme.onSurfaceVariant),
    );
  }
}
