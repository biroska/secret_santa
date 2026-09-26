/**
 * Lógica pura de geração do sorteio (sem dependência do Firestore), para
 * facilitar testes e reuso.
 */

export interface DrawParticipant {
  participantId: string;
  isDependent: boolean;
  canSortResponsible: boolean;
  responsibleIds: string[];
}

export interface DrawPair {
  giverId: string;
  receiverId: string;
}

/** Erro lançado quando não é possível gerar um sorteio válido. */
export class ImpossibleDrawError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "ImpossibleDrawError";
  }
}

function shuffle<T>(items: T[], random: () => number): T[] {
  const result = [...items];
  for (let i = result.length - 1; i > 0; i--) {
    const j = Math.floor(random() * (i + 1));
    [result[i], result[j]] = [result[j], result[i]];
  }
  return result;
}

/**
 * Retorna o conjunto de participantIds que o `giver` NÃO pode presentear:
 * - ele mesmo (não pode se autossortear);
 * - se for dependente e `canSortResponsible` for false, seus responsáveis.
 */
function forbiddenReceiverIdsFor(giver: DrawParticipant): Set<string> {
  const forbidden = new Set<string>([giver.participantId]);
  if (giver.isDependent && !giver.canSortResponsible) {
    for (const responsibleId of giver.responsibleIds) {
      forbidden.add(responsibleId);
    }
  }
  return forbidden;
}

/**
 * Gera um emparelhamento giver -> receiver respeitando as restrições, usando
 * backtracking com embaralhamento aleatório dos candidatos em cada passo.
 *
 * @param participants Lista de participantes do evento.
 * @param random Gerador de número aleatório em [0, 1). Injetável para testes.
 * @throws {ImpossibleDrawError} se nenhum emparelhamento válido existir.
 */
export function generateDraw(
  participants: DrawParticipant[],
  random: () => number = Math.random
): DrawPair[] {
  if (participants.length < 2) {
    throw new ImpossibleDrawError(
      "É necessário ao menos 2 participantes para realizar o sorteio."
    );
  }

  const ids = participants.map((p) => p.participantId);
  const uniqueIds = new Set(ids);
  if (uniqueIds.size !== ids.length) {
    throw new ImpossibleDrawError(
      "Existem participantes com participantId duplicado no evento."
    );
  }

  const forbiddenByGiver = new Map<string, Set<string>>();
  for (const participant of participants) {
    forbiddenByGiver.set(
      participant.participantId,
      forbiddenReceiverIdsFor(participant)
    );
  }

  for (const participant of participants) {
    const invalidResponsibleIds = participant.responsibleIds.filter(
      (responsibleId) => !uniqueIds.has(responsibleId)
    );
    if (invalidResponsibleIds.length > 0) {
      throw new ImpossibleDrawError(
        `O participante "${participant.participantId}" possui responsáveis ` +
          "que não pertencem ao evento. Corrija os dados antes de sortear."
      );
    }

    const allowedReceiverIds = ids.filter(
      (id) => !forbiddenByGiver.get(participant.participantId)!.has(id)
    );
    if (allowedReceiverIds.length === 0) {
      throw new ImpossibleDrawError(
        `O participante "${participant.participantId}" não pode ser ` +
          "sorteado para presentear ninguém com as restrições atuais " +
          "(verifique dependentes e responsáveis)."
      );
    }
  }

  // Ordena os "givers" pela quantidade de receivers permitidos (mais
  // restritos primeiro), o que acelera bastante o backtracking.
  const orderedGivers = shuffle(participants, random).sort((a, b) => {
    const allowedA = ids.length - forbiddenByGiver.get(a.participantId)!.size;
    const allowedB = ids.length - forbiddenByGiver.get(b.participantId)!.size;
    return allowedA - allowedB;
  });

  const usedReceivers = new Set<string>();
  const assignment = new Map<string, string>();

  function backtrack(index: number): boolean {
    if (index === orderedGivers.length) return true;

    const giver = orderedGivers[index];
    const forbidden = forbiddenByGiver.get(giver.participantId)!;
    const candidates = shuffle(
      ids.filter((id) => !forbidden.has(id) && !usedReceivers.has(id)),
      random
    );

    for (const candidate of candidates) {
      usedReceivers.add(candidate);
      assignment.set(giver.participantId, candidate);

      if (backtrack(index + 1)) return true;

      usedReceivers.delete(candidate);
      assignment.delete(giver.participantId);
    }

    return false;
  }

  const solved = backtrack(0);
  if (!solved) {
    throw new ImpossibleDrawError(
      "Não foi possível gerar um sorteio válido com as restrições atuais " +
        "(verifique dependentes e seus responsáveis)."
    );
  }

  return orderedGivers.map((giver) => ({
    giverId: giver.participantId,
    receiverId: assignment.get(giver.participantId)!,
  }));
}
