// Backup da tela de detalhes do evento
// Arquivo original: lib/features/events/presentation/event_details_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../dtos/event_card_dto.dart';

class EventDetailsScreen extends StatelessWidget {
  final EventCardDto event;

  const EventDetailsScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.name,
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Organizador: ${event.organizerName}',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                'Data do Evento',
                dateFormat.format(event.eventDate),
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                'Data do Sorteio',
                dateFormat.format(event.drawDate),
              ),
              const SizedBox(height: 16),
              Text(
                event.description,
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Text(value),
      ],
    );
  }
}
