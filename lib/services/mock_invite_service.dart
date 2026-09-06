import 'dart:async';

import '../models/participant_invite_model.dart';

class MockInviteService {
  /// Retorna dados de convite mock para um eventId (valores fixos nesta fase)
  Future<ParticipantInviteModel> getInviteForEvent(String eventId) async {
    // Simula latência
    await Future.delayed(const Duration(milliseconds: 300));

    return ParticipantInviteModel(
      qrAsset: 'assets/images/mock-Adicionar-Participante.png',
      inviteCode: 'DIA-CRIANCAS-4821',
      inviteLink: 'https://example.com/invite/DIA-CRIANCAS-4821',
      title: 'Participante',
      subtitle: 'Peça para escanear o QR Code ou envie o link do evento.',
    );
  }
}
