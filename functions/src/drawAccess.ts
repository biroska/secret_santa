export class InvalidLinkedDependentError extends Error {}

export function getLinkedDependentIds(
  participants: unknown[],
  responsibleParticipantId: string
): string[] {
  const dependentIds: string[] = [];

  for (const rawParticipant of participants) {
    if (
      !rawParticipant ||
      typeof rawParticipant !== "object" ||
      Array.isArray(rawParticipant)
    ) {
      continue;
    }

    const participant = rawParticipant as Record<string, unknown>;
    if (
      participant.isDependent !== true ||
      !Array.isArray(participant.responsibleIds) ||
      !participant.responsibleIds.includes(responsibleParticipantId)
    ) {
      continue;
    }

    if (
      typeof participant.participantId !== "string" ||
      participant.participantId.length === 0
    ) {
      throw new InvalidLinkedDependentError(
        "Dependente vinculado não possui participantId válido."
      );
    }

    dependentIds.push(participant.participantId);
  }

  return [...new Set(dependentIds)];
}
