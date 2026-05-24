import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Importar para Timestamp

class EventCardDto {
  final String name;
  final String organizerName; // Novo campo para o nome do organizador
  final DateTime eventDate;
  final DateTime drawDate;
  final IconData icon;

  EventCardDto({
    required this.name,
    required this.organizerName, // Tornando obrigatório
    required this.eventDate,
    required this.drawDate,
    this.icon = Icons.event, // Ícone padrão
  });

  // Construtor de fábrica para criar EventCardDto a partir de dados do Firestore
  // Este construtor será ajustado no EventService para incluir o organizerName
  factory EventCardDto.fromFirestore({
    required Map<String, dynamic> data,
    required String organizerName, // Recebe o nome do organizador
  }) {
    final Timestamp eventTimestamp = data['eventDate'] as Timestamp;
    final Timestamp drawTimestamp = data['createdAt'] as Timestamp; // Assumindo que drawDate é createdAt

    return EventCardDto(
      name: data['title'] as String,
      organizerName: organizerName,
      eventDate: eventTimestamp.toDate(),
      drawDate: drawTimestamp.toDate(),
      icon: Icons.event, // Usando um ícone padrão por enquanto
    );
  }
}