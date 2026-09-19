import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_keys.dart';
import '../../../services/firestore/event_service.dart';

/// Tela exibida imediatamente após o app ser aberto por um link de convite
/// (`https://.../event/<eventId>`, `secretsanta://event/<eventId>` ou
/// `secretsanta://invite/<eventId>`).
///
/// Ela silenciosamente garante que o usuário logado esteja vinculado ao
/// evento (adicionando-o como participante se necessário) e então navega
/// para a tela apropriada, notificando o resultado.
class EventInviteScreen extends StatefulWidget {
  final String eventId;
  final EventService eventService;

  const EventInviteScreen({
    super.key,
    required this.eventId,
    required this.eventService,
  });

  @override
  State<EventInviteScreen> createState() => _EventInviteScreenState();
}

class _EventInviteScreenState extends State<EventInviteScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleInvite());
  }

  void _notify(String message) {
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _goToNotFound() {
    if (!mounted) return;
    context.go('/home');
    _notify('Evento não encontrado.');
  }

  void _goToEvent(String message) {
    if (!mounted) return;
    context.go('/event-details/${widget.eventId}');
    _notify(message);
  }

  Future<void> _handleInvite() async {
    final eventId = widget.eventId.trim();
    if (eventId.isEmpty) {
      _goToNotFound();
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      // Segurança extra: a rota já garante login antes de chegar aqui.
      if (!mounted) return;
      context.go('/login?invite=${Uri.encodeComponent(eventId)}');
      return;
    }

    try {
      final status = await widget.eventService.joinEventForInvite(eventId, uid);
      switch (status) {
        case EventInviteJoinStatus.notFound:
          _goToNotFound();
          break;
        case EventInviteJoinStatus.alreadyParticipant:
          _goToEvent('Você já participa deste evento.');
          break;
        case EventInviteJoinStatus.joinedNow:
          _goToEvent('Você entrou no evento!');
          break;
      }
    } catch (_) {
      _goToNotFound();
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
