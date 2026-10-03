import 'package:flutter/material.dart';

/// Card padrão do app: usa o `cardTheme` (mesmo estilo da listagem de eventos).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin,
    this.color,
    this.onTap,
    this.fullWidth = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final VoidCallback? onTap;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);
    final content = Padding(padding: padding, child: child);
    final card = Card(
      margin: margin,
      color: color ?? Colors.white,
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : InkWell(onTap: onTap, borderRadius: radius, child: content),
    );
    return fullWidth ? SizedBox(width: double.infinity, child: card) : card;
  }
}
