/// Representa um evento com título, descrição, administrador, datas e participantes.
import 'participants.dart';

class Events {
  const Events({
    required this.id,
    required this.title,
    required this.description,
    required this.adminId,
    required this.status,
    required this.eventDate,
    required this.createdAt,
    required this.participants,
  });

  final String id;
  final String title;
  final String description;
  final String adminId;
  final String status;
  final DateTime eventDate;
  final DateTime createdAt;
  final List<Participants> participants;

  factory Events.fromJson(Map<String, dynamic> json) {
    return Events(
      id: json['id'] as String? ?? '',
      title: json['title'] as String,
      description: json['description'] as String,
      adminId: json['adminId'] as String,
      status: json['status'] as String,
      eventDate: DateTime.parse(json['eventDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      participants: (json['participants'] as List<dynamic>?)
              ?.map((e) => Participants.fromJson(e as Map<String, dynamic>))
              .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'adminId': adminId,
        'status': status,
        'eventDate': _dateOnlyIso(eventDate),
        'createdAt': createdAt.toUtc().toIso8601String(),
        'participants': participants.map((p) => p.toJson()).toList(),
      };

  static String _dateOnlyIso(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
