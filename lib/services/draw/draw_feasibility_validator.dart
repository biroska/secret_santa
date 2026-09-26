/// Validação pura (sem Firestore/Cloud Functions) de viabilidade do sorteio.
///
/// Espelha exatamente as mesmas regras usadas no backend
/// (`functions/src/drawLogic.ts`), para que "viável no Flutter" nunca
/// divirja de "viável na Cloud Function":
/// - ninguém pode ser sorteado para si mesmo;
/// - um participante dependente (`isDependent == true`) que não pode
///   sortear responsáveis (`canSortResponsible == false`) não pode ser
///   sorteado para presentear nenhum de seus `responsibleIds`.
///
/// O problema é modelado como um emparelhamento bipartido: de um lado os
/// "sorteadores" (givers), do outro os "sorteados" (receivers) - mesmo
/// conjunto de IDs dos dois lados. O sorteio é viável se, e somente se,
/// existir um emparelhamento perfeito (todos os givers emparelhados) nesse
/// grafo, o que é decidido aqui via algoritmo de Kuhn (busca de caminhos
/// aumentantes para emparelhamento bipartido máximo).
library;

/// Restrições de um participante relevantes para a viabilidade do sorteio.
class DrawParticipantConstraint {
  const DrawParticipantConstraint({
    required this.participantId,
    this.name,
    this.isDependent = false,
    this.canSortResponsible = false,
    this.responsibleIds = const [],
  });

  final String participantId;
  final String? name;
  final bool isDependent;
  final bool canSortResponsible;
  final List<String> responsibleIds;
}

/// Resultado da validação de viabilidade do sorteio.
class DrawFeasibilityResult {
  const DrawFeasibilityResult({
    required this.isFeasible,
    required this.message,
    this.blockedParticipantIds = const [],
  });

  /// `true` se existe uma atribuição giver->receiver válida.
  final bool isFeasible;

  /// Mensagem amigável (pt-BR) explicando o motivo quando inviável, ou uma
  /// confirmação quando viável.
  final String message;

  /// IDs dos participantes que não puderam ser emparelhados, quando
  /// inviável. Útil para diagnóstico/mensagens mais específicas.
  final List<String> blockedParticipantIds;
}

/// Valida se a configuração atual de participantes/dependentes permite gerar
/// um sorteio válido, sem chamar a Cloud Function `performDraw`.
class DrawFeasibilityValidator {
  const DrawFeasibilityValidator._();

  /// Adapta os mapas crus já usados em `EventCardDto.participants` (mesmos
  /// campos gravados no Firestore: `participantId`, `isDependent`,
  /// `canSortResponsible`, `responsibleIds`) e roda [validate].
  static DrawFeasibilityResult validateRawParticipants(
    List<Map<String, dynamic>> rawParticipants,
  ) {
    final constraints = <DrawParticipantConstraint>[];
    for (var index = 0; index < rawParticipants.length; index++) {
      final raw = rawParticipants[index];
      final participantId = raw['participantId'];
      if (participantId is! String || participantId.isEmpty) {
        return DrawFeasibilityResult(
          isFeasible: false,
          message:
              'Participante no índice $index não possui participantId válido.',
        );
      }
      final responsibleIds = (raw['responsibleIds'] as List<dynamic>?)
              ?.map((id) => id.toString())
              .toList() ??
          const <String>[];

      constraints.add(
        DrawParticipantConstraint(
          participantId: participantId,
          name: raw['name'] is String ? raw['name'] as String : null,
          isDependent: (raw['isDependent'] as bool?) ?? false,
          canSortResponsible: (raw['canSortResponsible'] as bool?) ?? false,
          responsibleIds: responsibleIds,
        ),
      );
    }
    return validate(constraints);
  }

  /// Verifica se existe um emparelhamento giver->receiver que respeite todas
  /// as restrições (ninguém se autossorteia; dependentes sem
  /// `canSortResponsible` não presenteiam seus responsáveis).
  static DrawFeasibilityResult validate(
    List<DrawParticipantConstraint> participants,
  ) {
    if (participants.length < 2) {
      return const DrawFeasibilityResult(
        isFeasible: false,
        message: 'É necessário ao menos 2 participantes para realizar o sorteio.',
      );
    }

    final ids = participants.map((p) => p.participantId).toList();
    if (ids.toSet().length != ids.length) {
      return const DrawFeasibilityResult(
        isFeasible: false,
        message:
            'Existem participantes com identificador duplicado no evento. '
            'Corrija os dados do evento antes de sortear.',
      );
    }

    final participantIds = ids.toSet();

    // Lista de candidatos (receivers) permitidos para cada giver.
    final allowedReceivers = <String, List<String>>{};
    for (final participant in participants) {
      final participantName = _firstName(participant);
      final invalidResponsibleIds = participant.responsibleIds
          .where((id) => !participantIds.contains(id))
          .toList();
      if (invalidResponsibleIds.isNotEmpty) {
        return DrawFeasibilityResult(
          isFeasible: false,
          message:
              'O participante "$participantName" possui '
              'responsáveis que não pertencem ao evento. Corrija os dados '
              'antes de sortear.',
          blockedParticipantIds: [participant.participantId],
        );
      }

      final forbidden = <String>{participant.participantId};
      if (participant.isDependent && !participant.canSortResponsible) {
        forbidden.addAll(participant.responsibleIds);
      }

      final candidates =
          ids.where((id) => !forbidden.contains(id)).toList();
      allowedReceivers[participant.participantId] = candidates;

      if (candidates.isEmpty) {
        return DrawFeasibilityResult(
          isFeasible: false,
          message:
              'O participante "$participantName" não pode ser '
              'sorteado para presentear ninguém com as restrições atuais '
              '(verifique dependentes e responsáveis).',
          blockedParticipantIds: [participant.participantId],
        );
      }
    }

    // Emparelhamento bipartido máximo (algoritmo de Kuhn / caminhos
    // aumentantes): receiverId -> giverId atualmente emparelhado a ele.
    final matchOfReceiver = <String, String>{};

    bool tryAssign(String giver, Set<String> visitedReceivers) {
      for (final receiver in allowedReceivers[giver]!) {
        if (visitedReceivers.contains(receiver)) continue;
        visitedReceivers.add(receiver);

        final currentGiver = matchOfReceiver[receiver];
        if (currentGiver == null ||
            tryAssign(currentGiver, visitedReceivers)) {
          matchOfReceiver[receiver] = giver;
          return true;
        }
      }
      return false;
    }

    final unmatchedGivers = <String>[];
    for (final giverId in ids) {
      if (!tryAssign(giverId, <String>{})) {
        unmatchedGivers.add(giverId);
      }
    }

    if (unmatchedGivers.isEmpty) {
      return const DrawFeasibilityResult(
        isFeasible: true,
        message: 'Sorteio viável com as restrições atuais.',
      );
    }

    return DrawFeasibilityResult(
      isFeasible: false,
      message:
          'Não é possível gerar um sorteio válido com as restrições atuais '
          '(verifique dependentes e seus responsáveis).',
      blockedParticipantIds: unmatchedGivers,
    );
  }

  static String _firstName(DrawParticipantConstraint participant) {
    final normalizedName = participant.name?.trim() ?? '';
    if (normalizedName.isEmpty) return 'Participante';
    return normalizedName.split(RegExp(r'\s+')).first;
  }
}
