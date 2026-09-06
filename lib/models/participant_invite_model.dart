class ParticipantInviteModel {
  final String qrAsset; // caminho do asset da imagem do QR
  final String inviteCode;
  final String inviteLink;
  final String title;
  final String subtitle;

  ParticipantInviteModel({
    required this.qrAsset,
    required this.inviteCode,
    required this.inviteLink,
    required this.title,
    required this.subtitle,
  });

  factory ParticipantInviteModel.fromJson(Map<String, dynamic> json) {
    return ParticipantInviteModel(
      qrAsset: json['qrAsset'] as String? ?? '',
      inviteCode: json['inviteCode'] as String? ?? '',
      inviteLink: json['inviteLink'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'qrAsset': qrAsset,
        'inviteCode': inviteCode,
        'inviteLink': inviteLink,
        'title': title,
        'subtitle': subtitle,
      };
}
