import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../auth/data/google_auth_result.dart';
import '../../../services/firestore/event_service.dart';

class ScanInviteScreen extends StatefulWidget {
  const ScanInviteScreen({super.key});

  @override
  State<ScanInviteScreen> createState() => _ScanInviteScreenState();
}

class _ScanInviteScreenState extends State<ScanInviteScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final _eventService = EventService();
  bool _scanned = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Aceita tanto o código puro quanto um link escaneado/colado
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

  Future<void> _joinEventCode(String rawCode) async {
    final normalizedCode = _extractEventCode(rawCode);
    if (normalizedCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código do evento não foi encontrado')),
      );
      return;
    }

    if (_isLoading) return;

    setState(() => _isLoading = true);

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Código do evento não foi encontrado')),
        );
        // Permite tentar escanear novamente.
        _scanned = false;
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você entrou no evento com sucesso!')),
      );
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        context.go(
          '/home',
          extra: GoogleAuthResult(
            firebaseUid: currentUser.uid,
            email: currentUser.email ?? '',
            displayName: currentUser.displayName,
            photoUrl: currentUser.photoURL,
          ),
        );
      } else {
        context.go('/home');
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível entrar no evento.')),
      );
      _scanned = false;
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onDetect(dynamic capture) {
    if (_scanned) return;
    String raw = '';

    // Try several access patterns to be compatible with different mobile_scanner versions
    try {
      // Case: capture has .barcodes (BarcodeCapture)
      final barcodes = (capture as dynamic).barcodes;
      if (barcodes is List && barcodes.isNotEmpty) {
        final first = barcodes.first;
        raw = (first.rawValue ?? first?.value ?? '') as String;
      }
    } catch (_) {
      // ignore
    }

    if (raw.isEmpty) {
      try {
        // Case: capture itself is a Barcode-like object
        raw = (capture as dynamic).rawValue ?? (capture as dynamic).value ?? '';
      } catch (_) {
        // ignore
      }
    }

    if (raw.isEmpty) return;

    _scanned = true;
    try {
      _controller.stop();
    } catch (_) {}

    _joinEventCode(raw);
  }

  @override
  Widget build(BuildContext context) {
    // On web/desktop, mobile_scanner may not be supported — fall back to paste UI
    if (kIsWeb || ![TargetPlatform.android, TargetPlatform.iOS].contains(defaultTargetPlatform)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Escanear convite')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Scanner indisponível nesta plataforma. Cole o conteúdo do QR abaixo:'),
              const SizedBox(height: 12),
              _PasteFallback(
                isLoading: _isLoading,
                onSubmit: (value) => _joinEventCode(value),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear convite'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          if (_isLoading)
            const ColoredBox(
              color: Colors.black45,
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

class _PasteFallback extends StatefulWidget {
  final void Function(String) onSubmit;
  final bool isLoading;
  const _PasteFallback({required this.onSubmit, this.isLoading = false});
  @override
  State<_PasteFallback> createState() => _PasteFallbackState();
}

class _PasteFallbackState extends State<_PasteFallback> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    widget.onSubmit(value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _controller,
          decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Conteúdo do QR / URL'),
          minLines: 1,
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: widget.isLoading ? null : _submit,
          child: widget.isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Usar conteúdo'),
        ),
      ],
    );
  }
}
