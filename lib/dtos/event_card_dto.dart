import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Importar para Timestamp

class EventCardDto {
  final String id;
  final String adminId;
  final String name;
  final String organizerName;
  final DateTime createdAt;
  final DateTime? eventDate;
  final DateTime? drawDate;
  final IconData icon;
  final String description;
  final int? maxGiftValue; // optional
  final List<Map<String, dynamic>>
  participants; // cada participante tem: userId, role, joinedAt, name, photoUrl

  EventCardDto({
    required this.id,
    required this.adminId,
    required this.name,
    required this.organizerName,
    required this.createdAt,
    this.eventDate,
    this.drawDate,
    this.icon = Icons.event,
    required this.description,
    this.maxGiftValue,
    this.participants = const [],
  });

  factory EventCardDto.fromFirestore({
    required String id,
    required Map<String, dynamic> data,
    required String organizerName,
  }) {
    final Timestamp createdAtTimestamp =
        (data['createdAt'] as Timestamp?) ?? Timestamp.now();
    final Timestamp? eventTimestamp = data['eventDate'] as Timestamp?;
    final Timestamp? drawTimestamp = data['drawDate'] as Timestamp?;

    // maxGiftValue may be stored as int or num
    final dynamic rawMax = data['maxGiftValue'];
    int? maxGift;
    if (rawMax is int) {
      maxGift = rawMax;
    } else if (rawMax is num) {
      maxGift = rawMax.toInt();
    }

    final rawParticipants = data['participants'] as List<dynamic>? ?? [];
    final participants = rawParticipants.map<Map<String, dynamic>>((p) {
      final map = Map<String, dynamic>.from(p as Map<String, dynamic>);
      // normalize joinedAt: if Timestamp -> toDate().toIso8601String(), if string keep
      final joinedRaw = map['joinedAt'];
      if (joinedRaw is Timestamp) {
        map['joinedAt'] = joinedRaw.toDate().toUtc().toIso8601String();
      }
      return map;
    }).toList();

    return EventCardDto(
      id: id,
      adminId: (data['adminId'] as String?) ?? '',
      name: data['title'] as String? ?? 'Evento sem título',
      organizerName: organizerName,
      createdAt: createdAtTimestamp.toDate(),
      eventDate: eventTimestamp?.toDate(),
      drawDate: drawTimestamp?.toDate(),
      icon: Icons.event,
      description: data['description'] as String? ?? '',
      maxGiftValue: maxGift,
      participants: participants,
    );
  }
}
