import 'package:flutter/material.dart';

import '../../../dtos/event_card_dto.dart';

class EventTitleCard extends StatelessWidget {
  final EventCardDto event;
  final bool isAdmin;
  final VoidCallback? onBack;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onDevAddAll;
  final bool showDrawValidationButton;
  final VoidCallback? onValidateDraw;
  final Color? backgroundColor;
  final bool includeOuterPadding;

  const EventTitleCard({
    super.key,
    required this.event,
    this.isAdmin = false,
    this.onBack,
    this.onEdit,
    this.onDelete,
    this.onDevAddAll,
    this.showDrawValidationButton = false,
    this.onValidateDraw,
    this.backgroundColor,
    this.includeOuterPadding = true,
  });

  @override
  Widget build(BuildContext context) {
    final bg =
        backgroundColor ??
        Theme.of(context).appBarTheme.backgroundColor ??
        Theme.of(context).colorScheme.primary;
    final organizerFirstName = _getFirstName(event.organizerName);

    final content = Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 22),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  event.name,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.7,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 8),
              if (isAdmin || showDrawValidationButton)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isAdmin)
                      IconButton(
                        onPressed: onDevAddAll,
                        icon: const Icon(Icons.add, color: Colors.white),
                        tooltip:
                            'DEV: adicionar todos usuários como participantes',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isAdmin && event.status != 'DRAWN')
                          IconButton(
                            onPressed: onEdit,
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: Colors.white,
                            ),
                            tooltip: 'Editar evento',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        if (isAdmin)
                          IconButton(
                            onPressed: onDelete,
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.white,
                            ),
                            tooltip: 'Excluir evento',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        if (showDrawValidationButton)
                          IconButton(
                            onPressed: onValidateDraw,
                            icon: const Icon(Icons.check, color: Colors.white),
                            tooltip: 'Validar sorteio',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            event.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Organizador: $organizerFirstName',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return includeOuterPadding
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: content,
          )
        : content;
  }

  String _getFirstName(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return 'Você';
    final parts = normalized
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return normalized;
    if (parts.length == 1) return parts.first;
    return '${parts[0]} ${parts[1]}';
  }
}
