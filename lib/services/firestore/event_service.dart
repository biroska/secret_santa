import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // Para debugPrint

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
}