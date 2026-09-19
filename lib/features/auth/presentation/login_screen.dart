import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:secret_santa/utils/app_routes.dart';

import '../data/google_auth_api.dart';
import '../data/google_auth_service.dart';
import 'package:sign_in_button/sign_in_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.auth, this.pendingEventId});

  final GoogleAuthApi auth;

  /// Id do evento de um convite pendente (deep link) recebido antes do login.
  /// Quando presente, após o login o usuário é levado direto para o fluxo de
  /// entrada no evento, em vez da Home.
  final String? pendingEventId;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _onGoogleSignIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.auth.signInWithGoogle();

      if (!mounted) return;
      if (result == null) {
        setState(() => _loading = false);
        return;
      }
      final pendingEventId = widget.pendingEventId?.trim();
      if (pendingEventId != null && pendingEventId.isNotEmpty) {
        context.go('/event/$pendingEventId', extra: result);
        return;
      }
      context.go( AppRoutes.HOME, extra: result);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message ?? e.code;
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message ?? e.code;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final supported = GoogleAuthService.isPlatformSupported;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              Icon(
                Icons.card_giftcard_rounded,
                size: 72,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Secret Santa',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Entre para participar do amigo secreto',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 40),
              if (!supported) ...[
                Text(
                  'Google Sign-In não está disponível nesta plataforma. '
                  'Use Android, iOS, macOS ou Web (Chrome).',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],

              if (_error != null) ...[
                Text(
                  _error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
              /*GoogleSignInButton(
                onPressed: supported ? _onGoogleSignIn : null,
                isLoading: _loading,
              ),*/
              Text( " Google login is supported? $supported" ),
              SignInButton(
                Buttons.google,
                onPressed: () {
                  _onGoogleSignIn();
                },
              ),
              const SizedBox(height: 16),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
