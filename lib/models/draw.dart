/// Par sorteado: quem presenteia e quem recebe.
class Draw {
  const Draw({required this.giverId, required this.receiverId});

  final String giverId;
  final String receiverId;

  factory Draw.fromJson(Map<String, dynamic> json) {
    return Draw(
      giverId: json['giverId'] as String,
      receiverId: json['receiverId'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'giverId': giverId,
    'receiverId': receiverId,
  };
}
