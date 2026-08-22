import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Importar para Timestamp

class EventCardDto {
  final String id;
  final String name;
  final String organizerName; // Novo campo para o nome do organizador
  final DateTime eventDate;
  final DateTime drawDate;
  final IconData icon;
  final String description; // Adicionando o campo de descrição

  EventCardDto({
    required this.id,
    required this.name,
    required this.organizerName, // Tornando obrigatório
    required this.eventDate,
    required this.drawDate,
    this.icon = Icons.event, // Ícone padrão
    required this.description, // Tornando obrigatório
  });

  // Construtor de fábrica para criar EventCardDto a partir de dados do Firestore
  // Este construtor será ajustado no EventService para incluir o organizerName
  factory EventCardDto.fromFirestore({
    required String id,
    required Map<String, dynamic> data,
    required String organizerName, // Recebe o nome do organizador
  }) {
    final Timestamp eventTimestamp = data['eventDate'] as Timestamp;
    final Timestamp drawTimestamp =
        (data['drawDate'] as Timestamp?) ??
        (data['createdAt'] as Timestamp? ?? Timestamp.now());

    return EventCardDto(
      id: id,
      name: data['title'] as String,
      organizerName: organizerName,
      eventDate: eventTimestamp.toDate(),
      drawDate: drawTimestamp.toDate(),
      icon: Icons.event, // Usando um ícone padrão por enquanto
      description:
          data['description'] as String, // Obtendo a descrição do Firestore
    );
  }
}
