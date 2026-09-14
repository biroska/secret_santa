import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanInviteScreen extends StatefulWidget {
  const ScanInviteScreen({super.key});

  @override
  State<ScanInviteScreen> createState() => _ScanInviteScreenState();
}

class _ScanInviteScreenState extends State<ScanInviteScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _scanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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

    // Return payload to previous screen
    try {
      context.pop(raw);
    } catch (_) {
      Navigator.of(context).pop(raw);
    }
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
              _PasteFallback(onSubmit: (value) {
                try {
                  context.pop(value);
                } catch (_) {
                  Navigator.of(context).pop(value);
                }
              }),
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
      body: MobileScanner(
        controller: _controller,
        onDetect: _onDetect,
      ),
    );
  }
}

class _PasteFallback extends StatefulWidget {
  final void Function(String) onSubmit;
  const _PasteFallback({required this.onSubmit});
  @override
  State<_PasteFallback> createState() => _PasteFallbackState();
}

class _PasteFallbackState extends State<_PasteFallback> {
  final _controller = TextEditingController();
  bool _processing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    setState(() => _processing = true);
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
        ElevatedButton(onPressed: _processing ? null : _submit, child: const Text('Usar conteúdo')),
      ],
    );
  }
}
