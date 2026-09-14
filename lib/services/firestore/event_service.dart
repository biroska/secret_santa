import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // Para debugPrint
import 'package:firebase_auth/firebase_auth.dart'; // Para FirebaseAuth
import '../../dtos/new_event_dto.dart'; // Importando o NewEventDto
import '../../dtos/event_card_dto.dart'; // Importando o EventCardDto
import 'user_service.dart'; // Importando o UserService

class EventService {
  final FirebaseFirestore _firestore;
  final UserService _userService; // Adicionando UserService como dependência

  EventService({FirebaseFirestore? firestore, UserService? userService})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _userService = userService ?? UserService(); // Inicializando UserService

  String? _currentUserId() => FirebaseAuth.instance.currentUser?.uid;

  bool _isUserParticipant(Map<String, dynamic> data, String userId) {
    final adminId = (data['adminId'] ?? '').toString();
    if (adminId == userId) return true;

    final participants = (data['participants'] as List<dynamic>?) ?? const [];
    for (final entry in participants) {
      if (entry is! Map) continue;
      final participantMap = Map<String, dynamic>.from(entry);
      final participantUserId = (participantMap['userId'] ?? '').toString();
      if (participantUserId == userId) return true;
    }

    return false;
  }

  int _compareEventDatesForDisplay(
    Map<String, dynamic> left,
    Map<String, dynamic> right,
  ) {
    final leftDate = (left['eventDate'] as Timestamp?)?.toDate();
    final rightDate = (right['eventDate'] as Timestamp?)?.toDate();

    if (leftDate == null && rightDate == null) {
      final leftCreated = (left['createdAt'] as Timestamp?)?.toDate();
      final rightCreated = (right['createdAt'] as Timestamp?)?.toDate();
      if (leftCreated == null || rightCreated == null) return 0;
      return rightCreated.compareTo(leftCreated);
    }

    if (leftDate == null) return 1;
    if (rightDate == null) return -1;

    return rightDate.compareTo(leftDate);
  }

  List<Map<String, dynamic>> _filterEventsForCurrentUser(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final currentUserId = _currentUserId();
    if (currentUserId == null || currentUserId.isEmpty) {
      return const [];
    }

    final filtered = <Map<String, dynamic>>[];
    for (final doc in docs) {
      final data = doc.data();
      if (data.isEmpty) continue;
      if (_isUserParticipant(data, currentUserId)) {
        filtered.add({'id': doc.id, ...data});
      }
    }

    filtered.sort(_compareEventDatesForDisplay);

    return filtered;
  }

  /// Adiciona um participante ao evento se ele ainda não existir.
  /// Usa uma transação para garantir consistência.
  Future<void> addParticipantIfNotExists(
    String eventId,
    String userId, {
    String role = 'PARTICIPANT',
  }) async {
    final docRef = _firestore.collection('events').doc(eventId);
    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) throw Exception('Evento não encontrado');

        final data = snapshot.data();
        final participants = (data?['participants'] as List<dynamic>?) ?? [];
        final exists = participants.any((p) => (p['userId'] ?? '') == userId);
        if (exists) return; // já existe, nada a fazer

        final participantIndex = participants.length + 1;
        final participantEntry = {
          'participantId': 'P$participantIndex',
          'userId': userId,
          'role': role,
          'isDependent': false,
          'responsibleIds': <String>[],
          'giftWish': <String>[],
          'joinedAt': DateTime.now().toUtc().toIso8601String(),
        };

        transaction.update(docRef, {
          'participants': FieldValue.arrayUnion([participantEntry]),
        });
      });
    } catch (e) {
      debugPrint(
        'Erro ao adicionar participante $userId ao evento $eventId: $e',
      );
      rethrow;
    }
  }

  Future<bool> joinEventByCode(String eventCode, String userId) async {
    final docRef = _firestore.collection('events').doc(eventCode);
    try {
      final snapshot = await docRef.get();
      if (!snapshot.exists || snapshot.data() == null) {
        return false;
      }

      await addParticipantIfNotExists(eventCode, userId);
      return true;
    } catch (e) {
      debugPrint('Erro ao entrar no evento $eventCode: $e');
      return false;
    }
  }

  Future<void> addDependentParticipant(
    String eventId, {
    required String dependentName,
    required List<String> responsibleIds,
    bool canSortResponsible = false,
  }) async {
    final docRef = _firestore.collection('events').doc(eventId);
    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          throw Exception('Evento não encontrado');
        }

        final data = snapshot.data() ?? {};
        final participants = (data['participants'] as List<dynamic>?) ?? const [];
        final dependentCount = participants.where((participant) {
          if (participant is! Map) return false;
          final map = Map<String, dynamic>.from(participant);
          return (map['isDependent'] as bool? ?? false) == true;
        }).length;

        final participantId = 'D${dependentCount + 1}';
        final cleanName = dependentName.trim();
        final sanitizedResponsibleIds = responsibleIds
            .map((id) => id.trim())
            .where((id) => id.isNotEmpty)
            .toList();

        final participantEntry = {
          'participantId': participantId,
          'userId': 'dependent-$participantId',
          'name': cleanName,
          'role': 'DEPENDENT',
          'isDependent': true,
          'responsibleIds': sanitizedResponsibleIds,
          'canSortResponsible': canSortResponsible,
          'giftWish': <String>[],
          'joinedAt': DateTime.now().toUtc().toIso8601String(),
        };

        transaction.update(docRef, {
          'participants': [...participants, participantEntry],
        });
      });
    } catch (e) {
      debugPrint(
        'Erro ao adicionar dependente ao evento $eventId: $e',
      );
      rethrow;
    }
  }

  Future<List<EventCardDto>> getEvents() async {
    try {
      final querySnapshot = await _firestore
          .collection('events')
          .orderBy('eventDate', descending: true)
          .get();

      final filteredDocs = _filterEventsForCurrentUser(querySnapshot.docs);
      final List<EventCardDto> events = [];

      for (final docData in filteredDocs) {
        final String adminId = (docData['adminId'] ?? '').toString();

        String organizerName = 'Desconhecido';
        try {
          final user = await _userService.getUserById(adminId);
          organizerName = user?.name ?? 'Desconhecido';
        } catch (e) {
          debugPrint('Erro ao buscar organizador $adminId: $e');
        }

        events.add(
          EventCardDto.fromFirestore(
            id: docData['id'] as String,
            data: docData,
            organizerName: organizerName,
          ),
        );
      }

      events.sort((a, b) {
        final left = a.eventDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final right = b.eventDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        if (a.eventDate == null && b.eventDate == null) return 0;
        if (a.eventDate == null) return 1;
        if (b.eventDate == null) return -1;
        return right.compareTo(left);
      });
      return events;
    } catch (e) {
      debugPrint('Erro ao buscar eventos do Firestore: $e');
      return [];
    }
  }

  Future<EventCardDto?> getEventById(String eventId) async {
    try {
      final docSnapshot = await _firestore
          .collection('events')
          .doc(eventId)
          .get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data()!;
        final String adminId = data['adminId'] as String;

        String organizerName = 'Desconhecido';
        try {
          final user = await _userService.getUserById(adminId);
          organizerName = user?.name ?? 'Desconhecido';
        } catch (e) {
          debugPrint(
            'Erro ao buscar organizador $adminId para evento $eventId: $e',
          );
        }

        // Enriquecer participantes com nome e photoUrl quando possível
        final rawParticipants = (data['participants'] as List<dynamic>?) ?? [];
        final List<Map<String, dynamic>> enriched = [];
        for (var p in rawParticipants) {
          try {
            final map = Map<String, dynamic>.from(p as Map<String, dynamic>);
            final uid = (map['userId'] ?? '').toString();
            final existingName = (map['name'] as String?)?.trim();
            final existingPhotoUrl = (map['photoUrl'] as String?)?.trim();
            String name = existingName ?? '';
            String photoUrl = existingPhotoUrl ?? '';
            try {
              final user = await _userService.getUserById(uid);
              if (user != null) {
                if (name.isEmpty) {
                  name = user.name;
                }
                if (photoUrl.isEmpty) {
                  photoUrl = user.photoUrl;
                }
              }
            } catch (e) {
              debugPrint('Erro ao buscar info de usuário $uid: $e');
            }
            map['name'] = name;
            map['photoUrl'] = photoUrl;
            enriched.add(map);
          } catch (e) {
            debugPrint('Participante inválido no evento $eventId: $e');
          }
        }

        // Substitui participants pelo enriquecido temporariamente para o DTO
        final enrichedData = Map<String, dynamic>.from(data);
        enrichedData['participants'] = enriched;

        return EventCardDto.fromFirestore(
          id: docSnapshot.id,
          data: enrichedData,
          organizerName: organizerName,
        );
      }
      return null;
    } catch (e) {
      debugPrint('Erro ao buscar evento $eventId do Firestore: $e');
      return null;
    }
  }

  /// Busca uma página de eventos ordenados por eventDate desc.
  /// Se [startAfter] for fornecido, retorna eventos com eventDate < startAfter (ou seja, mais antigos).
  Future<List<EventCardDto>> getEventsPage({
    DateTime? startAfter,
    int limit = 10,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('events')
          .orderBy('eventDate', descending: true)
          .get();

      final filteredDocs = _filterEventsForCurrentUser(querySnapshot.docs);
      final List<Map<String, dynamic>> ordered = [...filteredDocs];

      if (startAfter != null) {
        ordered.removeWhere((item) {
          final value = (item['eventDate'] as Timestamp?)?.toDate();
          return value == null || !value.isBefore(startAfter);
        });
      }

      final paginated = ordered.length > limit
          ? ordered.sublist(0, limit)
          : ordered;

      final List<EventCardDto> events = [];

      for (final docData in paginated) {
        final String adminId = (docData['adminId'] ?? '').toString();

        String organizerName = 'Desconhecido';
        try {
          final user = await _userService.getUserById(adminId);
          organizerName = user?.name ?? 'Desconhecido';
        } catch (e) {
          debugPrint('Erro ao buscar organizador $adminId: $e');
        }

        events.add(
          EventCardDto.fromFirestore(
            id: docData['id'] as String,
            data: docData,
            organizerName: organizerName,
          ),
        );
      }

      return events;
    } catch (e) {
      debugPrint('Erro ao buscar página de eventos do Firestore: $e');
      return [];
    }
  }

  Future<void> updateDrawDate(String eventId, {DateTime? drawDate}) async {
    try {
      final targetDate = drawDate ?? DateTime.now();
      final normalized = DateTime.utc(
        targetDate.year,
        targetDate.month,
        targetDate.day,
        12,
        0,
        0,
      );

      await _firestore.collection('events').doc(eventId).update({
        'drawDate': Timestamp.fromDate(normalized),
        'status': 'CREATED',
      });

      debugPrint(
        'Data de sorteio atualizada para $eventId em ${normalized.toIso8601String()} e status definido como CREATED.',
      );
    } catch (e) {
      debugPrint('Erro ao atualizar a data de sorteio do evento $eventId: $e');
      rethrow;
    }
  }

  Future<String> createEvent(NewEventDto newEvent) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado.');
      }

      // Ajustar a data do evento para 12:00:00 UTC
      final DateTime eventDateUtc = DateTime.utc(
        newEvent.eventDate.year,
        newEvent.eventDate.month,
        newEvent.eventDate.day,
        12,
        0,
        0,
      );

      final createdAt = Timestamp.now();

      final participantEntry = {
        'participantId': 'P1',
        'userId': user.uid,
        'role': 'ADMIN',
        'isDependent': false,
        'responsibleIds': <String>[],
        'giftWish': <String>[],
        'joinedAt': createdAt.toDate().toUtc().toIso8601String(),
      };

      // Gerar documento com ID e usar docRef.set para garantir que o id esteja disponível
      final docRef = _firestore.collection('events').doc();
      final id = docRef.id;

      final eventData = {
        'id': id,
        'title': newEvent.title,
        'description': newEvent.description,
        'eventDate': Timestamp.fromDate(eventDateUtc),
        'createdAt': createdAt,
        'adminId': user.uid,
        'status': 'CREATING',
        'participants': [participantEntry],
      };

      // Incluir maxGiftValue se estiver definido (usar variável local para evitar problema de promoção de tipo)
      final maxGift = newEvent.maxGiftValue;
      if (maxGift != null) {
        eventData['maxGiftValue'] = maxGift;
      }

      await docRef.set(eventData);
      debugPrint(
        'Evento "${newEvent.title}" criado com sucesso no Firestore com id $id.',
      );
      return id;
    } catch (e) {
      debugPrint('Erro ao criar evento no Firestore: $e');
      rethrow; // Re-lança o erro para ser tratado na UI
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      await _firestore.collection('events').doc(eventId).delete();
      debugPrint('Evento $eventId removido do Firestore.');
    } catch (e) {
      debugPrint('Erro ao remover evento $eventId do Firestore: $e');
      rethrow;
    }
  }
}
