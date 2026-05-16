import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Importar para Timestamp

class EventCardDto {
  final String name;
  final DateTime eventDate;
  final DateTime drawDate;
  final IconData icon;

  EventCardDto({
    required this.name,
    required this.eventDate,
    required this.drawDate,
    this.icon = Icons.event, // Ícone padrão
  });

  // Construtor de fábrica para criar EventCardDto a partir de dados do Firestore
  factory EventCardDto.fromFirestore(Map<String, dynamic> data) {
    // Assumindo que 'eventDate' e 'drawDate' são Timestamps do Firestore
    final Timestamp eventTimestamp = data['eventDate'] as Timestamp;
    final Timestamp drawTimestamp = data['createdAt'] as Timestamp;

    // Para o ícone, podemos ter um mapeamento de string para IconData,
    // ou simplesmente usar um padrão se não for fornecido ou reconhecido.
    // Por simplicidade, vamos usar um padrão por enquanto.
    // Se você tiver um campo 'iconName' no Firestore, pode fazer algo como:
    // final String? iconName = data['iconName'] as String?;
    // IconData iconData = _mapIconNameToIconData(iconName); // Função auxiliar para mapear

    return EventCardDto(
      name: data['title'] as String,
      eventDate: eventTimestamp.toDate(),
      drawDate: drawTimestamp.toDate(),
      icon: Icons.event, // Usando um ícone padrão por enquanto
    );
  }
}

// Exemplo de função auxiliar para mapear string para IconData (se necessário)
// IconData _mapIconNameToIconData(String? iconName) {
//   switch (iconName) {
//     case 'business':
//       return Icons.business;
//     case 'family_restroom':
//       return Icons.family_restroom;
//     // Adicione mais casos conforme necessário
//     default:
//       return Icons.event;
//   }
// }