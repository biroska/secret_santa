import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // Para debugPrint
import 'package:firebase_auth/firebase_auth.dart'; // Para FirebaseAuth
import '../../dtos/new_event_dto.dart'; // Importando o NewEventDto

class EventService {
  final FirebaseFirestore _firestore;

  EventService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getEvents() async {
    try {
      final querySnapshot = await _firestore.collection('events').get();
      final events = querySnapshot.docs.map((doc) => doc.data()).toList();
      return events;
    } catch (e) {
      debugPrint('Erro ao buscar eventos do Firestore: $e');
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
        12, // 12:00:00 UTC
        0,
        0,
      );

      final eventData = {
        'title': newEvent.title,
        'description': newEvent.description,
        'eventDate': Timestamp.fromDate(eventDateUtc),
        'createdAt': Timestamp.now(), // Data e hora da gravação
        'adminId': user.uid,
        'status': 'CREATING', // Status fixo
      };

      await _firestore.collection('events').add(eventData);
      debugPrint('Evento "${newEvent.title}" criado com sucesso no Firestore.');
    } catch (e) {
      debugPrint('Erro ao criar evento no Firestore: $e');
      rethrow; // Re-lança o erro para ser tratado na UI
    }
  }
}