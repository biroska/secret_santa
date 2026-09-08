class NewEventDto {
  final String title;
  final String description;
  final DateTime eventDate;
  final int? maxGiftValue; // Valor máximo do presente (opcional)

  NewEventDto({
    required this.title,
    required this.description,
    required this.eventDate,
    this.maxGiftValue,
  });
}
