import 'package:flutter/material.dart';

import '../../../dtos/event_card_dto.dart';

class EventTitleCard extends StatelessWidget {
  final EventCardDto event;
  final bool isAdmin;
  final VoidCallback? onBack;
  final VoidCallback? onDelete;
  final VoidCallback? onDevAddAll;
  final Color? backgroundColor;
  final bool includeOuterPadding;

  const EventTitleCard({
    super.key,
    required this.event,
    this.isAdmin = false,
    this.onBack,
    this.onDelete,
    this.onDevAddAll,
    this.backgroundColor,
    this.includeOuterPadding = true,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).colorScheme.primary;
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
                IconButton(
                  onPressed: onBack ?? () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
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
                if (isAdmin)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: onDevAddAll,
                        icon: const Icon(Icons.add, color: Colors.white),
                        tooltip: 'DEV: adicionar todos usuários como participantes',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      IconButton(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                        tooltip: 'Excluir evento',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              event.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 14,
                    color: Color(0xFF1D7B72),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Organizado por: $organizerFirstName',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                const Text('🎄', style: TextStyle(fontSize: 18)),
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
    final parts = normalized.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return normalized;
    if (parts.length == 1) return parts.first;
    return '${parts[0]} ${parts[1]}';
  }
}
