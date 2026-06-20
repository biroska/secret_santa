import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../dtos/event_card_dto.dart';
import '../../../services/firestore/event_service.dart';

class EventDetailsScreen extends StatefulWidget {
  final String eventId;

  const EventDetailsScreen({super.key, required this.eventId});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  late final EventService _eventService;
  Future<EventCardDto?>? _eventFuture; // Changed to nullable Future

  @override
  void initState() {
    super.initState();
    _eventService = EventService();
    _fetchEventDetails();
  }

  @override
  void didUpdateWidget(covariant EventDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.eventId != oldWidget.eventId) {
      _fetchEventDetails();
    }
  }

  Future<void> _fetchEventDetails() async {
    setState(() {
      _eventFuture = _eventService.getEventById(widget.eventId).then((event) {
        return event; // This can now be null
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd-MM-yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Evento'),
      ),
      body: FutureBuilder<EventCardDto?>( // Changed to nullable FutureBuilder
        future: _eventFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar evento: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) { // Explicitly check for null
            return const Center(child: Text('Nenhum evento encontrado.'));
          } else {
            final event = snapshot.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.name, // Usando o nome do evento real
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Divider(height: 32),
                  _buildInfoField("Título", event.name),
                  _buildInfoField("Organizador", event.organizerName),
                  _buildInfoField("Data do Evento", dateFormat.format(event.eventDate)),
                  _buildInfoField("Data do Sorteio", dateFormat.format(event.drawDate)),
                  _buildInfoField("ID Interno", event.id),
                  const SizedBox(height: 24),
                  const Text(
                    "Descrição",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      event.description, // Usando a descrição real
                      style: const TextStyle(fontSize: 16, height: 1.4),
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}