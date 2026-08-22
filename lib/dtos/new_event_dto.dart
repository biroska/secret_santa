class NewEventDto {
  final String title;
  final String description;
  final DateTime eventDate;
  final DateTime drawDate;

  NewEventDto({
    required this.title,
    required this.description,
    required this.eventDate,
    required this.drawDate,
  });
}
