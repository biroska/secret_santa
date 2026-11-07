import 'package:flutter/material.dart';

import '../../../dtos/event_card_dto.dart';

class EventTitleCard extends StatelessWidget {
  final EventCardDto event;
  final bool isAdmin;
  final VoidCallback? onBack;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showDrawValidationButton;
  final VoidCallback? onValidateDraw;
  final bool includeOuterPadding;

  const EventTitleCard({
    super.key,
    required this.event,
    this.isAdmin = false,
    this.onBack,
    this.onEdit,
    this.onDelete,
    this.showDrawValidationButton = false,
    this.onValidateDraw,
    this.includeOuterPadding = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final organizerFirstName = _getFirstName(event.organizerName);

    final content = Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: colorScheme.primary,
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
                  style: TextStyle(
                    color: colorScheme.onPrimary,
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
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isAdmin && event.status != 'DRAWN')
                          IconButton(
                            onPressed: onEdit,
                            icon: Icon(
                              Icons.edit_outlined,
                              color: colorScheme.onPrimary,
                              size: 18,
                            ),
                            tooltip: 'Editar evento',
                            padding: EdgeInsets.zero,
                            style: IconButton.styleFrom(
                              minimumSize: const Size(22, 20),
                              fixedSize: const Size(22, 20),
                              maximumSize: const Size(22, 20),
                              padding: EdgeInsets.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        if (isAdmin)
                          IconButton(
                            onPressed: onDelete,
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: colorScheme.onPrimary,
                              size: 18,
                            ),
                            tooltip: 'Excluir evento',
                            padding: EdgeInsets.zero,
                            style: IconButton.styleFrom(
                              minimumSize: const Size(22, 20),
                              fixedSize: const Size(22, 20),
                              maximumSize: const Size(22, 20),
                              padding: EdgeInsets.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        if (showDrawValidationButton)
                          IconButton(
                            onPressed: onValidateDraw,
                            icon: Icon(
                              Icons.check,
                              color: colorScheme.onPrimary,
                            ),
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
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Organizador: $organizerFirstName',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimary,
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
