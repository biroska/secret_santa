import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../auth/data/google_auth_api.dart';
import '../../auth/data/google_auth_result.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.auth,
    required this.session,
  });

  final GoogleAuthApi auth;
  final GoogleAuthResult session;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _signingOut = false;

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    try {
      await widget.auth.signOut();
      if (!mounted) return;
      context.go('/login');
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = widget.session.displayName ?? widget.session.email;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Início'),
        actions: [
          TextButton(
            onPressed: _signingOut ? null : _signOut,
            child: _signingOut
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.onPrimary,
                    ),
                  )
                : const Text('Sair'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Você entrou',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              widget.session.email,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (widget.session.idToken != null) ...[
              const SizedBox(height: 24),
              Text(
                'idToken recebido — pronto para enviar ao backend ou Firebase.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
