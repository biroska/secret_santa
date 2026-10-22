import 'package:firebase_messaging/firebase_messaging.dart';

enum PushNotificationType { drawCompleted, unknown }

class PushNotificationPayload {
  const PushNotificationPayload({
    required this.type,
    this.eventId,
    this.eventTitle,
    this.title,
    this.body,
  });

  final PushNotificationType type;
  final String? eventId;
  final String? eventTitle;
  final String? title;
  final String? body;

  bool get isDrawCompleted => type == PushNotificationType.drawCompleted;

  String? get deepLinkRoute {
    final id = eventId?.trim();
    if (id == null || id.isEmpty || !isDrawCompleted) return null;
    return '/event-details/${Uri.encodeComponent(id)}';
  }

  factory PushNotificationPayload.fromRemoteMessage(RemoteMessage message) {
    final data = message.data;
    final type = switch (data['type']?.toString()) {
      'draw_completed' => PushNotificationType.drawCompleted,
      _ => PushNotificationType.unknown,
    };

    return PushNotificationPayload(
      type: type,
      eventId: data['eventId']?.toString(),
      eventTitle: data['eventTitle']?.toString(),
      title: message.notification?.title,
      body: message.notification?.body,
    );
  }

  String get displayBody {
    final messageBody = body?.trim();
    if (messageBody != null && messageBody.isNotEmpty) return messageBody;
    final name = eventTitle?.trim();
    if (name != null && name.isNotEmpty) {
      return 'O sorteio do evento "$name" foi realizado.';
    }
    return 'O sorteio foi realizado.';
  }
}
