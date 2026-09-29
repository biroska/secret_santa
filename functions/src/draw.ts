import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import {
  DrawParticipant,
  generateDraw,
  ImpossibleDrawError,
  validateDrawAssignments,
} from "./drawLogic";

interface PerformDrawRequest {
  eventId: string;
}

/**
 * Cloud Function callable que executa o sorteio de um evento.
 *
 * Regras:
 * - Somente o admin do evento pode chamar.
 * - O evento precisa estar com status "CREATED" (data do sorteio já
 *   confirmada) e ainda não ter sido sorteado.
 * - Um participante nunca é sorteado para si mesmo.
 * - Um participante dependente com canSortResponsible=false não pode ser
 *   sorteado para presentear nenhum de seus responsibleIds.
 *
 * Resultado é gravado, em uma única transação, em:
 * - subcoleção "events/{eventId}/draws" (um documento por giverId, contendo
 *   apenas giverId e receiverId);
 * - o próprio documento do evento tem o status atualizado para "DRAWN".
 */
export const performDraw = onCall<PerformDrawRequest>(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError(
      "unauthenticated",
      "É necessário estar autenticado para realizar o sorteio."
    );
  }

  const eventId = request.data?.eventId;
  if (!eventId || typeof eventId !== "string") {
    throw new HttpsError(
      "invalid-argument",
      "O parâmetro eventId é obrigatório."
    );
  }

  const db = getFirestore();
  const eventRef = db.collection("events").doc(eventId);

  const pairs = await db.runTransaction(async (transaction) => {
    const eventSnap = await transaction.get(eventRef);
    if (!eventSnap.exists) {
      throw new HttpsError("not-found", "Evento não encontrado.");
    }

    const eventData = eventSnap.data() ?? {};

    if (eventData.adminId !== uid) {
      throw new HttpsError(
        "permission-denied",
        "Somente o administrador do evento pode realizar o sorteio."
      );
    }

    if (eventData.status === "DRAWN") {
      throw new HttpsError(
        "failed-precondition",
        "O sorteio deste evento já foi realizado."
      );
    }

    if (eventData.status !== "CREATED") {
      throw new HttpsError(
        "failed-precondition",
        "Confirme a data do sorteio antes de realizar o sorteio."
      );
    }

    const rawParticipants = (eventData.participants as unknown[]) ?? [];
    const participants: DrawParticipant[] = rawParticipants.map(
      (raw, index) => {
        const p = raw as Record<string, unknown>;
        const participantId = p.participantId as string | undefined;
        if (!participantId) {
          throw new HttpsError(
            "failed-precondition",
            `Participante no índice ${index} não possui participantId.`
          );
        }
        return {
          participantId,
          isDependent: (p.isDependent as boolean) ?? false,
          canSortResponsible: (p.canSortResponsible as boolean) ?? false,
          responsibleIds: Array.isArray(p.responsibleIds)
            ? (p.responsibleIds as string[])
            : [],
        };
      }
    );

    let generatedPairs;
    try {
      generatedPairs = generateDraw(participants);
    } catch (error) {
      if (error instanceof ImpossibleDrawError) {
        throw new HttpsError("failed-precondition", error.message);
      }
      throw error;
    }

    const drawsCollection = eventRef.collection("draws");

    for (const pair of generatedPairs) {
      const docData = {
        giverId: pair.giverId,
        receiverId: pair.receiverId,
      };

      transaction.set(drawsCollection.doc(pair.giverId), docData);
    }

    transaction.update(eventRef, {
      status: "DRAWN",
      drawnAt: FieldValue.serverTimestamp(),
    });

    return generatedPairs;
  });

  logger.info(`Sorteio do evento ${eventId} concluído por ${uid}`, {
    eventId,
    pairsCount: pairs.length,
  });

  return { success: true, pairsCount: pairs.length };
});

interface GetMyDrawRequest {
  eventId: string;
}

/**
 * Retorna somente o resultado do participante autenticado.
 */
export const getMyDraw = onCall<GetMyDrawRequest>(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError(
      "unauthenticated",
      "É necessário estar autenticado para revelar seu amigo secreto."
    );
  }

  const eventId = request.data?.eventId;
  if (!eventId || typeof eventId !== "string") {
    throw new HttpsError(
      "invalid-argument",
      "O parâmetro eventId é obrigatório."
    );
  }

  const eventRef = getFirestore().collection("events").doc(eventId);
  const eventSnapshot = await eventRef.get();
  if (!eventSnapshot.exists) {
    throw new HttpsError("not-found", "Evento não encontrado.");
  }

  const eventData = eventSnapshot.data() ?? {};
  if (eventData.status !== "DRAWN") {
    throw new HttpsError(
      "failed-precondition",
      "O sorteio deste evento ainda não foi realizado."
    );
  }

  const participants = (eventData.participants as unknown[]) ?? [];
  const participant = participants.find((raw) => {
    if (!raw || typeof raw !== "object") return false;
    return (raw as Record<string, unknown>).userId === uid;
  }) as Record<string, unknown> | undefined;

  if (!participant || typeof participant.participantId !== "string") {
    throw new HttpsError(
      "permission-denied",
      "Você não participa deste evento."
    );
  }

  const giverId = participant.participantId;
  const drawSnapshot = await eventRef
    .collection("draws")
    .doc(giverId)
    .get();
  const receiverId = drawSnapshot.data()?.receiverId;
  if (typeof receiverId !== "string") {
    throw new HttpsError(
      "not-found",
      "O resultado do sorteio não foi encontrado para o participante atual."
    );
  }

  return { receiverId };
});

interface ValidateEventDrawRequest {
  eventId: string;
}

export const validateEventDraw = onCall<ValidateEventDrawRequest>(
  async (request) => {
    const uid = request.auth?.uid;
    const email = request.auth?.token.email;
    if (
      uid !== "Gj0YNtyFsQXNOrjgYPj6OJ2WarC2" ||
      typeof email !== "string" ||
      email.toLowerCase() !== "biroska@gmail.com"
    ) {
      throw new HttpsError(
        "permission-denied",
        "Você não tem permissão para validar este sorteio."
      );
    }

    const eventId = request.data?.eventId;
    if (!eventId || typeof eventId !== "string") {
      throw new HttpsError(
        "invalid-argument",
        "O parâmetro eventId é obrigatório."
      );
    }

    const eventRef = getFirestore().collection("events").doc(eventId);
    const eventSnapshot = await eventRef.get();
    if (!eventSnapshot.exists) {
      throw new HttpsError("not-found", "Evento não encontrado.");
    }

    const eventData = eventSnapshot.data() ?? {};
    if (eventData.status !== "DRAWN") {
      throw new HttpsError(
        "failed-precondition",
        "O sorteio deste evento ainda não foi realizado."
      );
    }

    const rawParticipants = Array.isArray(eventData.participants)
      ? eventData.participants
      : [];
    const participants: DrawParticipant[] = rawParticipants.map(
      (raw, index) => {
        if (!raw || typeof raw !== "object") {
          throw new HttpsError(
            "failed-precondition",
            `Participante no índice ${index} possui formato inválido.`
          );
        }
        const participant = raw as Record<string, unknown>;
        const participantId = participant.participantId;
        if (typeof participantId !== "string" || participantId.length === 0) {
          throw new HttpsError(
            "failed-precondition",
            `Participante no índice ${index} não possui participantId válido.`
          );
        }
        return {
          participantId,
          isDependent: participant.isDependent === true,
          canSortResponsible: participant.canSortResponsible === true,
          responsibleIds: Array.isArray(participant.responsibleIds)
            ? participant.responsibleIds.filter(
                (id): id is string => typeof id === "string"
              )
            : [],
        };
      }
    );
    const drawsSnapshot = await eventRef.collection("draws").get();
    const issues = validateDrawAssignments(
      drawsSnapshot.docs.map((doc) => doc.data()),
      participants
    );

    return { issues };
  }
);
