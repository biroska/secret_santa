import 'package:flutter/material.dart';

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
}