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

  /// Adiciona um participante ao evento se ele ainda não existir.
  /// Usa uma transação para garantir consistência.
  Future<void> addParticipantIfNotExists(String eventId, String userId, {String role = 'PARTICIPANT'}) async {
    final docRef = _firestore.collection('events').doc(eventId);
    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) throw Exception('Evento não encontrado');

        final data = snapshot.data() as Map<String, dynamic>?;
        final participants = (data?['participants'] as List<dynamic>?) ?? [];
        final exists = participants.any((p) => (p['userId'] ?? '') == userId);
        if (exists) return; // já existe, nada a fazer

        final participantEntry = {
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
      debugPrint('Erro ao adicionar participante $userId ao evento $eventId: $e');
      rethrow;
    }
  }

  Future<List<EventCardDto>> getEvents() async {
    try {
      final querySnapshot = await _firestore
          .collection('events')
          .orderBy('eventDate', descending: true)
          .get();
      final List<EventCardDto> events = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final String adminId = data['adminId'] as String;

        // Buscar o nome do organizador usando UserService
        String organizerName = 'Desconhecido';
        try {
          final user = await _userService.getUserById(adminId);
          organizerName = user?.name ?? 'Desconhecido'; // Usando user.name
        } catch (e) {
          debugPrint('Erro ao buscar organizador $adminId: $e');
        }

        events.add(
          EventCardDto.fromFirestore(
            id: doc.id, // Adicionando o ID do documento
            data: data,
            organizerName: organizerName,
          ),
        );
      }

      events.sort((a, b) => b.eventDate.compareTo(a.eventDate));
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
              final uid = (map['userId'] ?? '') as String;
              String name = '';
              String photoUrl = '';
              try {
                final user = await _userService.getUserById(uid);
                if (user != null) {
                  name = user.name;
                  photoUrl = user.photoUrl;
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
  Future<List<EventCardDto>> getEventsPage({DateTime? startAfter, int limit = 10}) async {
    try {
      Query query = _firestore.collection('events').orderBy('eventDate', descending: true).limit(limit);
      if (startAfter != null) {
        // Filtra eventos mais antigos que startAfter (startAfter é DateTime local)
        final Timestamp ts = Timestamp.fromDate(DateTime.utc(startAfter.year, startAfter.month, startAfter.day, 12));
        query = _firestore
            .collection('events')
            .where('eventDate', isLessThan: ts)
            .orderBy('eventDate', descending: true)
            .limit(limit);
      }

      final querySnapshot = await query.get();
      final List<EventCardDto> events = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue; // pular documentos sem dados
        final String adminId = (data['adminId'] ?? '') as String;

        String organizerName = 'Desconhecido';
        try {
          final user = await _userService.getUserById(adminId);
          organizerName = user?.name ?? 'Desconhecido';
        } catch (e) {
          debugPrint('Erro ao buscar organizador $adminId: $e');
        }

        events.add(
          EventCardDto.fromFirestore(
            id: doc.id,
            data: data,
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

  Future<void> createEvent(NewEventDto newEvent) async {
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

      final DateTime drawDateUtc = DateTime.utc(
        newEvent.drawDate.year,
        newEvent.drawDate.month,
        newEvent.drawDate.day,
        12,
        0,
        0,
      );

      final createdAt = Timestamp.now();

      final participantEntry = {
        'userId': user.uid,
        'role': 'ADMIN',
        'isDependent': false,
        'responsibleIds': <String>[],
        'giftWish': <String>[],
        'joinedAt': createdAt.toDate().toUtc().toIso8601String(),
      };

      final eventData = {
        'title': newEvent.title,
        'description': newEvent.description,
        'eventDate': Timestamp.fromDate(eventDateUtc),
        'drawDate': Timestamp.fromDate(drawDateUtc),
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

      await _firestore.collection('events').add(eventData);
      debugPrint('Evento "${newEvent.title}" criado com sucesso no Firestore.');
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
