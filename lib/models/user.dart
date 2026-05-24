/// Representa um usuário com dados de perfil e metadados.
class Users {
  const Users({
    required this.id,
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String photoUrl;
  final DateTime createdAt;

  factory Users.fromJson(Map<String, dynamic> json) {
    return Users(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      photoUrl: json['photoUrl'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'photoUrl': photoUrl,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };
}
