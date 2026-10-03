import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:secret_santa/utils/app_routes.dart';

import '../data/google_auth_api.dart';
import '../data/google_auth_service.dart';
import '../../../theme/app_colors.dart';
import 'widgets/google_sign_in_button.dart';

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
      context.go(AppRoutes.HOME, extra: result);
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
    const mutedText = Color(0xFF64748B);

    return Scaffold(
      backgroundColor: AppColors.surfaceTintBlue,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD6E4FF),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.card_giftcard_outlined,
                        size: 40,
                        color: Color(0xFF2B3F73),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Secret Santa',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0B1220),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Entre para participar do amigo secreto',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: mutedText),
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
                  GoogleSignInButton(
                    isLoading: _loading,
                    onPressed: _onGoogleSignIn,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Ao entrar você aceita os termos de uso e a política de privacidade.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: mutedText),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
