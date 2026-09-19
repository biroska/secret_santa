import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../auth/data/google_auth_result.dart';
import '../../../services/firestore/event_service.dart';

class JoinEventScreen extends StatefulWidget {
  /// Código do evento recebido via deep link (ex.: `secretsanta://invite/eventId`).
  final String? initialEventId;

  const JoinEventScreen({super.key, this.initialEventId});

  @override
  State<JoinEventScreen> createState() => _JoinEventScreenState();
}

class _JoinEventScreenState extends State<JoinEventScreen> {
  final _controller = TextEditingController();
  final _eventService = EventService();
  bool _showCodeError = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final initialCode = _extractEventCode(widget.initialEventId ?? '');
    if (initialCode.isNotEmpty) {
      _controller.text = initialCode;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (FirebaseAuth.instance.currentUser != null) {
          _joinEventCode(initialCode);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Faça login e toque em "Entrar" para participar do evento.'),
            ),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Aceita tanto o código puro quanto um link colado
  /// (ex.: `secretsanta://invite/id` ou `https://.../invite/id`),
  /// extraindo apenas o identificador do evento.
  String _extractEventCode(String rawInput) {
    final input = rawInput.trim();
    if (input.isEmpty) return '';

    final uri = Uri.tryParse(input);
    if (uri != null && (uri.hasScheme && uri.pathSegments.isNotEmpty)) {
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      final inviteIndex = segments.indexOf('invite');
      if (inviteIndex != -1 && inviteIndex + 1 < segments.length) {
        return segments[inviteIndex + 1];
      }
      if (uri.host == 'invite' && segments.isNotEmpty) {
        return segments.first;
      }
      if (segments.isNotEmpty) {
        return segments.last;
      }
    }

    return input;
  }

  void _resetCodeError() {
    if (_showCodeError) {
      setState(() => _showCodeError = false);
    }
  }

  Future<void> _joinEventCode(String code) async {
    final normalizedCode = _extractEventCode(code);
    if (normalizedCode.isEmpty) {
      setState(() => _showCodeError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o código do evento')),
      );
      return;
    }

    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _showCodeError = false;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuário não autenticado.')),
        );
        return;
      }

      final joined = await _eventService.joinEventByCode(normalizedCode, user.uid);

      if (!mounted) return;

      if (!joined) {
        setState(() => _showCodeError = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Código do evento não foi encontrado')),
        );
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Você entrou no evento com sucesso!')),
        );
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          context.go(
            '/home',
            extra: GoogleAuthResult(
              firebaseUid: user.uid,
              email: user.email ?? '',
              displayName: user.displayName,
              photoUrl: user.photoURL,
            ),
          );
        } else {
          context.go('/home');
        }
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _showCodeError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível entrar no evento.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _enterWithCode() async {
    await _joinEventCode(_controller.text);
  }

  Future<void> _scanQr() async {
    try {
      final result = await context.push('/scan-invite');
      if (!mounted) return;
      if (result != null && result is String) {
        final scannedCode = result.trim();
        if (scannedCode.isEmpty) {
          setState(() => _showCodeError = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Código do evento não foi encontrado')),
          );
          return;
        }

        _controller.text = scannedCode;
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: scannedCode.length),
        );
        await _joinEventCode(scannedCode);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível escanear o QR code.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrar em evento'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.qr_code),
                title: const Text('Escanear convite'),
                subtitle: const Text('Escaneie o QR Code do convite'),
                trailing: ElevatedButton(
                  onPressed: _scanQr,
                  child: const Text('Escanear'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Ou entre com o código do evento:'),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              onChanged: (_) {
                _resetCodeError();
                setState(() {});
              },
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: 'Código do evento',
                errorText: _showCodeError ? 'Código do evento não foi encontrado' : null,
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _controller.text.trim().isEmpty || _isLoading
                  ? null
                  : _enterWithCode,
              child: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Entrar'),
            ),
          ],
        ),
      ),
    );
  }
}
