import 'package:flutter_test/flutter_test.dart';
import 'package:secret_santa/services/notifications/push_notification_payload.dart';

void main() {
  group('PushNotificationPayload', () {
    test('routes draw-completed notifications to event details', () {
      const payload = PushNotificationPayload(
        type: PushNotificationType.drawCompleted,
        eventId: 'evt-123',
        eventTitle: 'Natal da Família',
      );

      expect(payload.deepLinkRoute, '/event-details/evt-123');
      expect(payload.isDrawCompleted, isTrue);
    });

    test('uses event title when notification body is empty', () {
      const payload = PushNotificationPayload(
        type: PushNotificationType.drawCompleted,
        eventTitle: 'Ceia',
      );

      expect(payload.displayBody, 'O sorteio do evento "Ceia" foi realizado.');
    });

    test('does not create a route without an event id', () {
      const payload = PushNotificationPayload(
        type: PushNotificationType.drawCompleted,
      );

      expect(payload.deepLinkRoute, isNull);
    });
  });
}
