import 'package:flutter/material.dart';

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.label = 'Entrar com o Google',
  });

  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.primary,
                ),
              )
            : Icon(Icons.login, color: theme.colorScheme.onSurface),
        label: Text(
          isLoading ? 'Entrando…' : label,
          style: theme.textTheme.titleMedium,
        ),
        style: OutlinedButton.styleFrom(
          alignment: Alignment.center,
          side: BorderSide(color: theme.colorScheme.outline),
        ),
      ),
    );
  }
}
