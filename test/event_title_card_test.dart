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
}
