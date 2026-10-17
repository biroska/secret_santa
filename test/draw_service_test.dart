import 'package:flutter_test/flutter_test.dart';
import 'package:secret_santa/services/firestore/draw_service.dart';

void main() {
  group('MyDrawResult.fromJson', () {
    test('parses the participant and linked dependent results', () {
      final result = MyDrawResult.fromJson({
        'receiverId': 'P2',
        'dependentDraws': [
          {'participantId': 'D1', 'receiverId': 'P3'},
          {'participantId': 'D2', 'receiverId': 'P1'},
        ],
      });

      expect(result.receiverId, 'P2');
      expect(
        result.dependentDraws
            .map((draw) => (draw.participantId, draw.receiverId))
            .toList(),
        [('D1', 'P3'), ('D2', 'P1')],
      );
    });

    test('rejects a response without dependent draw results', () {
      expect(
        () => MyDrawResult.fromJson({'receiverId': 'P2'}),
        throwsA(isA<DrawException>()),
      );
    });

    test('rejects invalid dependent draw entries', () {
      expect(
        () => MyDrawResult.fromJson({
          'receiverId': 'P2',
          'dependentDraws': [
            {'participantId': 'D1'},
          ],
        }),
        throwsA(isA<DrawException>()),
      );
    });
  });
}
