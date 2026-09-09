/// Participante de um evento (papel, dependentes, lista de desejos).
class Participants {
  const Participants({
    required this.userId,
    this.participantId,
    this.canSortResponsible = false,
    required this.role,
    required this.isDependent,
    required this.responsibleIds,
    required this.giftWish,
    required this.joinedAt,
  });

  final String userId;
  final String? participantId;
  final bool canSortResponsible;
  final String role;
  final bool isDependent;
  final List<String> responsibleIds;
  final List<String> giftWish;
  final DateTime joinedAt;

  factory Participants.fromJson(Map<String, dynamic> json) {
    return Participants(
      userId: json['userId'] as String? ?? '',
      participantId: json['participantId'] as String?,
      canSortResponsible: json['canSortResponsible'] as bool? ?? false,
      role: json['role'] as String? ?? 'PARTICIPANT',
      isDependent: json['isDependent'] as bool? ?? false,
      responsibleIds: List<String>.from(
        (json['responsibleIds'] as List<dynamic>? ?? const []),
      ),
      giftWish: List<String>.from(
        (json['giftWish'] as List<dynamic>? ?? const []),
      ),
      joinedAt: DateTime.parse(
        (json['joinedAt'] as String?) ?? DateTime.now().toUtc().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        if (participantId != null) 'participantId': participantId,
        'canSortResponsible': canSortResponsible,
        'role': role,
        'isDependent': isDependent,
        'responsibleIds': responsibleIds,
        'giftWish': giftWish,
        'joinedAt': joinedAt.toUtc().toIso8601String(),
      };
}
