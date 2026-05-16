/// Par sorteado: quem presenteia e quem recebe.
class Draw {
  const Draw({
    required this.giverId,
    required this.receiverId,
    required this.createdAt,
  });

  final String giverId;
  final String receiverId;
  final DateTime createdAt;

  factory Draw.fromJson(Map<String, dynamic> json) {
    return Draw(
      giverId: json['giverId'] as String,
      receiverId: json['receiverId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'giverId': giverId,
        'receiverId': receiverId,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };
}
