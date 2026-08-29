import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Importar para Timestamp

class EventCardDto {
  final String id;
  final String name;
  final String organizerName;
  final DateTime createdAt;
  final DateTime eventDate;
  final DateTime drawDate;
  final IconData icon;
  final String description;

  EventCardDto({
    required this.id,
    required this.name,
    required this.organizerName,
    required this.createdAt,
    required this.eventDate,
    required this.drawDate,
    this.icon = Icons.event,
    required this.description,
  });

  factory EventCardDto.fromFirestore({
    required String id,
    required Map<String, dynamic> data,
    required String organizerName,
  }) {
    final Timestamp createdAtTimestamp =
        (data['createdAt'] as Timestamp?) ?? Timestamp.now();
    final Timestamp eventTimestamp =
        (data['eventDate'] as Timestamp?) ?? createdAtTimestamp;
    final Timestamp drawTimestamp =
        (data['drawDate'] as Timestamp?) ?? createdAtTimestamp;

    return EventCardDto(
      id: id,
      name: data['title'] as String,
      organizerName: organizerName,
      createdAt: createdAtTimestamp.toDate(),
      eventDate: eventTimestamp.toDate(),
      drawDate: drawTimestamp.toDate(),
      icon: Icons.event,
      description: data['description'] as String? ?? '',
    );
  }
}
