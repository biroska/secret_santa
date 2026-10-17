import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secret_santa/dtos/event_card_dto.dart';
import 'package:secret_santa/features/events/presentation/event_title_card.dart';

EventCardDto _event({required String status}) => EventCardDto(
  id: 'event-1',
  adminId: 'admin-1',
  status: status,
  name: 'Amigo secreto',
  organizerName: 'Organizador',
  createdAt: DateTime(2026),
  description: 'Evento de teste',
);

void main() {
  testWidgets('shows the edit pencil above trash for admin before draw', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EventTitleCard(
            event: _event(status: 'CREATED'),
            isAdmin: true,
            onEdit: () {},
            onDelete: () {},
          ),
        ),
      ),
    );

    final editFinder = find.byTooltip('Editar evento');
    final deleteFinder = find.byTooltip('Excluir evento');
    expect(editFinder, findsOneWidget);
    expect(deleteFinder, findsOneWidget);
    expect(
      tester.getCenter(editFinder).dy,
      lessThan(tester.getCenter(deleteFinder).dy),
    );
  });

  testWidgets('hides edit pencil after draw and from non-admin users', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EventTitleCard(
            event: _event(status: 'DRAWN'),
            isAdmin: true,
            onEdit: () {},
            onDelete: () {},
          ),
        ),
      ),
    );
    expect(find.byTooltip('Editar evento'), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EventTitleCard(
            event: _event(status: 'CREATED'),
            isAdmin: false,
            onEdit: () {},
            onDelete: () {},
          ),
        ),
      ),
    );
    expect(find.byTooltip('Editar evento'), findsNothing);
    expect(find.byTooltip('Excluir evento'), findsNothing);
  });

  testWidgets(
    'reduces action spacing, description height, and bottom padding',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventTitleCard(
              event: _event(status: 'CREATED'),
              isAdmin: true,
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      final editButton = find.byTooltip('Editar evento');
      final deleteButton = find.byTooltip('Excluir evento');
      expect(
        tester.getCenter(deleteButton).dy - tester.getCenter(editButton).dy,
        lessThanOrEqualTo(22),
      );

      final description = tester.widget<Text>(find.text('Evento de teste'));
      expect(description.style!.height, 1);

      final cardContainer = tester.widget<Container>(
        find
            .ancestor(
              of: find.byTooltip('Editar evento'),
              matching: find.byType(Container),
            )
            .last,
      );
      expect(cardContainer.padding, const EdgeInsets.fromLTRB(12, 10, 12, 10));
    },
  );
}
