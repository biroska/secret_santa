/// Restrição de sorteio entre dois usuários (quem não pode tirar quem).
class Restrictions {
  const Restrictions({
    required this.fromUserId,
    required this.toUserId,
    required this.createdAt,
  });

  final String fromUserId;
  final String toUserId;
  final DateTime createdAt;

  factory Restrictions.fromJson(Map<String, dynamic> json) {
    return Restrictions(
      fromUserId: json['fromUserId'] as String,
      toUserId: json['toUserId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };
}
