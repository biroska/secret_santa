import 'package:flutter_test/flutter_test.dart';
import 'package:secret_santa/services/draw/draw_feasibility_validator.dart';

void main() {
  group('DrawFeasibilityValidator', () {
    test('sorteio viável com participantes sem restrições', () {
      final participants = [
        const DrawParticipantConstraint(participantId: 'P1'),
        const DrawParticipantConstraint(participantId: 'P2'),
        const DrawParticipantConstraint(participantId: 'P3'),
      ];

      final result = DrawFeasibilityValidator.validate(participants);

      expect(result.isFeasible, isTrue);
      expect(result.blockedParticipantIds, isEmpty);
    });

    test(
      'inviável quando um participante não pode presentear ninguém',
      () {
        final participants = [
          const DrawParticipantConstraint(
            participantId: 'P1',
            isDependent: true,
            canSortResponsible: false,
            responsibleIds: ['P2'],
          ),
          const DrawParticipantConstraint(participantId: 'P2'),
        ];

        final result = DrawFeasibilityValidator.validate(participants);

        expect(result.isFeasible, isFalse);
        expect(result.blockedParticipantIds, contains('P1'));
      },
    );

    test(
      'inviável quando dependentes cruzados esgotam todas as opções',
      () {
        // P1 é dependente de P2 (não pode presentear P2) e P2 é dependente
        // de P1 (não pode presentear P1). Com apenas 2 participantes, não
        // sobra nenhum par válido, mesmo cada um tendo "candidatos" antes
        // de remover a si mesmo.
        final participants = [
          const DrawParticipantConstraint(
            participantId: 'P1',
            isDependent: true,
            canSortResponsible: false,
            responsibleIds: ['P2'],
          ),
          const DrawParticipantConstraint(
            participantId: 'P2',
            isDependent: true,
            canSortResponsible: false,
            responsibleIds: ['P1'],
          ),
        ];

        final result = DrawFeasibilityValidator.validate(participants);

        expect(result.isFeasible, isFalse);
        expect(result.blockedParticipantIds, isNotEmpty);
      },
    );

    test(
      'inviável quando Bernardo não pode sortear nenhum dos dois responsáveis',
      () {
        final result = DrawFeasibilityValidator.validateRawParticipants([
          {'participantId': 'A', 'name': 'Aimbere'},
          {'participantId': 'L', 'name': 'Lilian'},
          {
            'participantId': 'B',
            'name': 'Bernardo da Silva',
            'isDependent': true,
            'canSortResponsible': false,
            'responsibleIds': ['A', 'L'],
          },
        ]);

        expect(result.isFeasible, isFalse);
        expect(result.blockedParticipantIds, contains('B'));
        expect(result.message, contains('Bernardo'));
        expect(result.message, isNot(contains('"B"')));
      },
    );

    test('inviável quando responsável não pertence ao evento', () {
      final participants = [
        const DrawParticipantConstraint(
          participantId: 'D1',
          isDependent: true,
          responsibleIds: ['unknown'],
        ),
        const DrawParticipantConstraint(participantId: 'P1'),
      ];

      final result = DrawFeasibilityValidator.validate(participants);

      expect(result.isFeasible, isFalse);
      expect(result.blockedParticipantIds, contains('D1'));
    });

    test('viável quando canSortResponsible libera a restrição', () {
      final participants = [
        const DrawParticipantConstraint(
          participantId: 'P1',
          isDependent: true,
          canSortResponsible: true,
          responsibleIds: ['P2'],
        ),
        const DrawParticipantConstraint(participantId: 'P2'),
      ];

      final result = DrawFeasibilityValidator.validate(participants);

      expect(result.isFeasible, isTrue);
    });

    test('inviável com menos de 2 participantes', () {
      final participants = [
        const DrawParticipantConstraint(participantId: 'P1'),
      ];

      final result = DrawFeasibilityValidator.validate(participants);

      expect(result.isFeasible, isFalse);
    });

    test('inviável com participantId duplicado', () {
      final participants = [
        const DrawParticipantConstraint(participantId: 'P1'),
        const DrawParticipantConstraint(participantId: 'P1'),
      ];

      final result = DrawFeasibilityValidator.validate(participants);

      expect(result.isFeasible, isFalse);
    });

    test('validateRawParticipants adapta os mapas do Firestore', () {
      final rawParticipants = [
        {'participantId': 'P1', 'isDependent': false, 'responsibleIds': []},
        {
          'participantId': 'P2',
          'name': 'Lilian Galdino',
          'isDependent': true,
          'canSortResponsible': false,
          'responsibleIds': ['P1'],
        },
        {'participantId': 'P3', 'isDependent': false, 'responsibleIds': []},
      ];

      final result =
          DrawFeasibilityValidator.validateRawParticipants(rawParticipants);

      expect(result.isFeasible, isTrue);
    });

    test('mensagem usa primeiro nome e não o ID quando não há opções', () {
      final result = DrawFeasibilityValidator.validate([
        const DrawParticipantConstraint(
          participantId: 'D7',
          name: 'Bernardo da Silva',
          isDependent: true,
          responsibleIds: ['P1', 'P2'],
        ),
        const DrawParticipantConstraint(participantId: 'P1'),
        const DrawParticipantConstraint(participantId: 'P2'),
      ]);

      expect(result.isFeasible, isFalse);
      expect(result.message, contains('"Bernardo"'));
      expect(result.message, isNot(contains('"D7"')));
    });

    test('usa rótulo genérico quando nome não está disponível', () {
      final result = DrawFeasibilityValidator.validate([
        const DrawParticipantConstraint(
          participantId: 'D7',
          isDependent: true,
          responsibleIds: ['P1'],
        ),
        const DrawParticipantConstraint(participantId: 'P1'),
      ]);

      expect(result.isFeasible, isFalse);
      expect(result.message, contains('"Participante"'));
      expect(result.message, isNot(contains('"D7"')));
    });

    test('inviável quando participantId está ausente nos dados crus', () {
      final result = DrawFeasibilityValidator.validateRawParticipants([
        {'isDependent': false},
        {'participantId': 'P2'},
      ]);

      expect(result.isFeasible, isFalse);
    });
  });
}
