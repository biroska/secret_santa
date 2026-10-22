/// Representa um usuário com dados de perfil e metadados.
class Users {
  const Users({
    required this.id,
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.createdAt,
    this.fcmTokens = const [],
  });

  final String id;
  final String name;
  final String email;
  final String photoUrl;
  final DateTime createdAt;
  final List<String> fcmTokens;

  factory Users.fromJson(Map<String, dynamic> json) {
    final rawTokens = json['fcmTokens'];
    return Users(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      photoUrl: json['photoUrl'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      fcmTokens: rawTokens is List
          ? rawTokens.whereType<String>().toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'photoUrl': photoUrl,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'fcmTokens': fcmTokens,
      };
}
