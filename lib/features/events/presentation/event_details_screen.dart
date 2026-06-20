import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventDetailsScreen extends StatelessWidget {
  final String eventId;

  const EventDetailsScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    // Dados mockados conforme solicitado
    const String title = "Amigo Secreto da Firma";
    const String description =
        "Evento anual para troca de presentes entre os colaboradores da unidade central.";
    final DateTime createdAt = DateTime.now().subtract(const Duration(days: 5));
    final DateTime eventDate = DateTime(2024, 12, 22);
    const String status = "Inscrições Abertas";
    const String headerTitle = "Amigo Ladrão da Empresa 213";

    final dateFormat = DateFormat('dd-MM-yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Evento'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título de destaque solicitado
            Text(
              headerTitle,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(height: 32),
            _buildInfoField("Título", title),
            _buildInfoField("Status", status),
            _buildInfoField("Data do Evento", dateFormat.format(eventDate)),
            _buildInfoField("Criado em", dateFormat.format(createdAt)),
            _buildInfoField("ID Interno", eventId),
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
                description,
                style: const TextStyle(fontSize: 16, height: 1.4),
              ),
            ),
          ],
        ),
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