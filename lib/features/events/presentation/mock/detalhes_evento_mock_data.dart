import '../../../../dtos/event_card_dto.dart';
import '../../../../models/event.dart';
import '../../../../models/participants.dart';

class MockParticipantEntry {
  const MockParticipantEntry({
    required this.participant,
    required this.displayName,
    required this.isCurrentUser,
  });

  final Participants participant;
  final String displayName;
  final bool isCurrentUser;
}

abstract final class DetalhesEventoMockData {
  DetalhesEventoMockData._();

  static const currentUserId = 'user-lucas';
  static const maxBudget = 80.0;

  static final eventCard = EventCardDto(
    id: 'mock-event-1',
    name: 'Amigo Secreto da Firma 🎄',
    organizerName: 'Lucas',
    createdAt: DateTime(2026, 5, 30),
    eventDate: DateTime(2026, 12, 24),
    drawDate: DateTime(2026, 12, 10),
    description: 'Amigo secreto de fim de ano da equipe.',
  );

  static final event = Events(
    title: 'Amigo Secreto da Firma 🎄',
    description: 'Amigo secreto de fim de ano da equipe.',
    adminId: currentUserId,
    status: 'DRAWN',
    eventDate: DateTime(2026, 12, 24),
    createdAt: DateTime(2026, 5, 30),
  );

  static const _defaultWishes = ['Livro', 'Caneca', 'Fone'];

  static final participants = [
    MockParticipantEntry(
      participant: Participants(
        userId: currentUserId,
        role: 'ORG',
        isDependent: false,
        responsibleIds: const [],
        giftWish: _defaultWishes,
        joinedAt: DateTime(2026, 5, 30),
      ),
      displayName: 'Lucas Silva',
      isCurrentUser: true,
    ),
    MockParticipantEntry(
      participant: Participants(
        userId: 'user-mariana',
        role: 'CONFIRMED',
        isDependent: false,
        responsibleIds: const [],
        giftWish: _defaultWishes,
        joinedAt: DateTime(2026, 6, 1),
      ),
      displayName: 'Mariana Souza',
      isCurrentUser: false,
    ),
    MockParticipantEntry(
      participant: Participants(
        userId: 'user-pedro',
        role: 'CONFIRMED',
        isDependent: false,
        responsibleIds: const [],
        giftWish: _defaultWishes,
        joinedAt: DateTime(2026, 6, 2),
      ),
      displayName: 'Pedro Alves',
      isCurrentUser: false,
    ),
    MockParticipantEntry(
      participant: Participants(
        userId: 'user-julia',
        role: 'CONFIRMED',
        isDependent: false,
        responsibleIds: const [],
        giftWish: _defaultWishes,
        joinedAt: DateTime(2026, 6, 3),
      ),
      displayName: 'Julia Costa',
      isCurrentUser: false,
    ),
    MockParticipantEntry(
      participant: Participants(
        userId: 'user-rafa',
        role: 'CONFIRMED',
        isDependent: false,
        responsibleIds: const [],
        giftWish: _defaultWishes,
        joinedAt: DateTime(2026, 6, 4),
      ),
      displayName: 'Rafael Mendes',
      isCurrentUser: false,
    ),
  ];
}
