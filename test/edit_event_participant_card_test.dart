import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secret_santa/features/events/presentation/edit_event_screen.dart';

void main() {
  testWidgets('shows a trash icon on the left for removable participants', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EditEventParticipantCard(
            participant: const {
              'participantId': 'P2',
              'userId': 'user-2',
              'name': 'João Silva',
              'role': 'PARTICIPANT',
              'isDependent': false,
            },
            adminId: 'admin-1',
            onRemove: () {},
            onEditDependent: () {},
          ),
        ),
      ),
    );

    final deleteButton = find.byTooltip('Remover participante');
    final avatar = find.byIcon(Icons.person);
    expect(deleteButton, findsOneWidget);
    expect(
      tester.getCenter(deleteButton).dx,
      lessThan(tester.getCenter(avatar).dx),
    );
    expect(find.byTooltip('Editar dependente'), findsNothing);
    expect(find.text('Participante'), findsOneWidget);
  });

  testWidgets('shows trash and edit icons on the left for dependents', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EditEventParticipantCard(
            participant: const {
              'participantId': 'D1',
              'userId': 'dependent-D1',
              'name': 'Ana',
              'role': 'DEPENDENT',
              'isDependent': true,
            },
            adminId: 'admin-1',
            onRemove: () {},
            onEditDependent: () {},
          ),
        ),
      ),
    );

    final deleteButton = find.byTooltip('Remover dependente');
    final editButton = find.byTooltip('Editar dependente');
    final avatar = find.byIcon(Icons.person);
    expect(deleteButton, findsOneWidget);
    expect(editButton, findsOneWidget);
    expect(
      tester.getCenter(deleteButton).dx,
      lessThan(tester.getCenter(avatar).dx),
    );
    expect(
      tester.getCenter(editButton).dx,
      lessThan(tester.getCenter(avatar).dx),
    );
    expect(find.text('Dependente'), findsOneWidget);
  });

  testWidgets('does not show removal controls for the event admin', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EditEventParticipantCard(
            participant: const {
              'participantId': 'P1',
              'userId': 'admin-1',
              'name': 'Marina',
              'role': 'ADMIN',
              'isDependent': false,
            },
            adminId: 'admin-1',
            onRemove: () {},
            onEditDependent: () {},
          ),
        ),
      ),
    );

    expect(find.byTooltip('Remover participante'), findsNothing);
    expect(find.byTooltip('Remover dependente'), findsNothing);
    expect(find.byTooltip('Editar dependente'), findsNothing);
    expect(find.text('Organizador'), findsOneWidget);
  });

  testWidgets('uses details-screen badge styling', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EditEventParticipantCard(
            participant: const {
              'participantId': 'P2',
              'userId': 'user-2',
              'name': 'João Silva',
              'role': 'PARTICIPANT',
              'isDependent': false,
            },
            adminId: 'admin-1',
            onRemove: () {},
            onEditDependent: () {},
          ),
        ),
      ),
    );

    final badge = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('Participante'),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = badge.decoration! as BoxDecoration;
    expect(decoration.color, const Color(0xFFE2F0E2));
    expect(
      (decoration.border! as Border).top.color,
      const Color(0xFF3D8F3D).withValues(alpha: 0.4),
    );
  });
}
