/// Participante de um evento (papel, dependentes, lista de desejos).
class Participants {
  const Participants({
    required this.userId,
    required this.role,
    required this.isDependent,
    required this.responsibleIds,
    required this.giftWish,
    required this.joinedAt,
  });

  final String userId;
  final String role;
  final bool isDependent;
  final List<String> responsibleIds;
  final List<String> giftWish;
  final DateTime joinedAt;

  factory Participants.fromJson(Map<String, dynamic> json) {
    return Participants(
      userId: json['userId'] as String,
      role: json['role'] as String,
      isDependent: json['isDependent'] as bool,
      responsibleIds:
          List<String>.from(json['responsibleIds'] as List<dynamic>),
      giftWish: List<String>.from(json['giftWish'] as List<dynamic>),
      joinedAt: DateTime.parse(json['joinedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'role': role,
        'isDependent': isDependent,
        'responsibleIds': responsibleIds,
        'giftWish': giftWish,
        'joinedAt': joinedAt.toUtc().toIso8601String(),
      };
}
