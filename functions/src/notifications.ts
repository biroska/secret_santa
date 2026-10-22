import * as logger from "firebase-functions/logger";
import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { getMessaging, MulticastMessage } from "firebase-admin/messaging";

export const DRAW_COMPLETED_TYPE = "draw_completed";

export const onEventDrawn = onDocumentUpdated(
  "events/{eventId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;
    if (before.status === "DRAWN" || after.status !== "DRAWN") return;

    const eventId = event.params.eventId;
    const title = typeof after.title === "string" ? after.title : "";
    const participants = Array.isArray(after.participants)
      ? after.participants
      : [];

    try {
      await notifyDrawCompleted(eventId, title, participants);
    } catch (error) {
      logger.error("Falha inesperada no trigger onEventDrawn", {
        eventId,
        error,
      });
    }
  }
);

interface ParticipantLike {
  userId?: unknown;
  isDependent?: unknown;
}

export function extractNotifiableUserIds(participants: unknown[]): string[] {
  const ids = new Set<string>();
  for (const raw of participants) {
    if (!raw || typeof raw !== "object") continue;
    const participant = raw as ParticipantLike;
    if (participant.isDependent === true) continue;
    if (
      typeof participant.userId !== "string" ||
      participant.userId.length === 0 ||
      participant.userId.startsWith("dependent-")
    ) {
      continue;
    }
    ids.add(participant.userId);
  }
  return [...ids];
}

function chunk<T>(items: T[], size: number): T[][] {
  const result: T[][] = [];
  for (let index = 0; index < items.length; index += size) {
    result.push(items.slice(index, index + size));
  }
  return result;
}

export async function notifyDrawCompleted(
  eventId: string,
  eventTitle: string,
  participants: unknown[]
): Promise<void> {
  const userIds = extractNotifiableUserIds(participants);
  if (userIds.length === 0) {
    logger.info("Nenhum participante elegível para push de sorteio.", {
      eventId,
    });
    return;
  }

  const db = getFirestore();
  const tokenToUser = new Map<string, string>();
  await Promise.all(
    userIds.map(async (uid) => {
      try {
        const snapshot = await db.collection("users").doc(uid).get();
        const tokens = snapshot.data()?.fcmTokens;
        if (!Array.isArray(tokens)) return;
        for (const token of tokens) {
          if (typeof token === "string" && token.length > 0) {
            tokenToUser.set(token, uid);
          }
        }
      } catch (error) {
        logger.warn(`Falha ao ler fcmTokens do usuário ${uid}`, { error });
      }
    })
  );

  const tokens = [...tokenToUser.keys()];
  if (tokens.length === 0) {
    logger.info("Nenhum fcmToken encontrado para notificar o sorteio.", {
      eventId,
      userCount: userIds.length,
    });
    return;
  }

  const safeTitle = eventTitle.trim() || "evento";
  const body =
    `O sorteio do evento "${safeTitle}" foi realizado. ` +
    "Revele seu amigo secreto.";
  const invalidTokens: string[] = [];

  for (const batch of chunk(tokens, 500)) {
    const message: MulticastMessage = {
      tokens: batch,
      notification: {
        title: "Sorteio realizado",
        body,
      },
      data: {
        type: DRAW_COMPLETED_TYPE,
        eventId,
        eventTitle: safeTitle,
      },
      android: {
        priority: "high",
        notification: {
          channelId: "draw_events",
          clickAction: "FLUTTER_NOTIFICATION_CLICK",
        },
      },
    };

    try {
      const response = await getMessaging().sendEachForMulticast(message);
      response.responses.forEach((result, index) => {
        if (result.success) return;
        const code = result.error?.code ?? "";
        logger.warn("Falha ao enviar push de sorteio", {
          eventId,
          code,
          message: result.error?.message,
        });
        if (
          code === "messaging/registration-token-not-registered" ||
          code === "messaging/invalid-registration-token"
        ) {
          invalidTokens.push(batch[index]);
        }
      });
      logger.info("Push de sorteio enviado", {
        eventId,
        batchSize: batch.length,
        successCount: response.successCount,
        failureCount: response.failureCount,
      });
    } catch (error) {
      logger.error("Erro ao chamar FCM no sorteio", { eventId, error });
    }
  }

  await Promise.all(
    invalidTokens.map(async (token) => {
      const uid = tokenToUser.get(token);
      if (!uid) return;
      try {
        await db
          .collection("users")
          .doc(uid)
          .update({ fcmTokens: FieldValue.arrayRemove(token) });
      } catch (error) {
        logger.warn(`Falha ao remover token inválido de ${uid}`, { error });
      }
    })
  );
}
