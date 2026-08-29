import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../dtos/event_card_dto.dart';
import '../../../services/firestore/event_service.dart';

class EventDetailsScreen extends StatefulWidget {
  final String eventId;

  const EventDetailsScreen({super.key, required this.eventId});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  late final EventService _eventService;
  Future<EventCardDto?>? _eventFuture;

  @override
  void initState() {
    super.initState();
    _eventService = EventService();
    _fetchEventDetails();
  }

  @override
  void didUpdateWidget(covariant EventDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.eventId != oldWidget.eventId) {
      _fetchEventDetails();
    }
  }

  Future<void> _fetchEventDetails() async {
    setState(() {
      _eventFuture = _eventService.getEventById(widget.eventId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<EventCardDto?>(
      future: _eventFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            body: Center(
              child: Text(
                'Erro ao carregar evento${snapshot.hasError ? ': ${snapshot.error}' : ''}',
              ),
            ),
          );
        }

        final event = snapshot.data!;
        final organizerFirstName = _getFirstName(event.organizerName);
        final shouldShowRevealBanner = event.drawDate.isBefore(DateTime.now());

        return Scaffold(
          backgroundColor: const Color(0xFFF2F3F5),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(context, event),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryCard(event),
                        const SizedBox(height: 18),
                        if (shouldShowRevealBanner) _buildRevealBanner(),
                        if (shouldShowRevealBanner) const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'Participantes',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B1B1B),
                              ),
                            ),
                            Text(
                              '5',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.add, size: 22),
                              label: const Text('Convidar'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF1D7B72),
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 0),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _buildSearchField(),
                        const SizedBox(height: 14),
                        _buildParticipantItem(
                          name: '$organizerFirstName (Você)',
                          subtitle: '3 desejos cadastrados',
                          badge: 'ORG',
                          badgeColor: const Color(0xFFD9E9E6),
                          badgeTextColor: const Color(0xFF1D7B72),
                          showChevron: true,
                        ),
                        const SizedBox(height: 12),
                        _buildParticipantItem(
                          name: 'Mariana Souza',
                          subtitle: '3 desejos cadastrados',
                          badge: 'Confirmado',
                          badgeColor: const Color(0xFFE2F0E2),
                          badgeTextColor: const Color(0xFF3D8F3D),
                          showChevron: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getFirstName(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return 'Você';
    }

    final parts = normalized.split(RegExp(r'\s+'));
    return parts.firstWhere((part) => part.isNotEmpty, orElse: () => normalized);
  }

  Widget _buildHeader(BuildContext context, EventCardDto event) {
    final appBarBackgroundColor =
        Theme.of(context).appBarTheme.backgroundColor ??
        Theme.of(context).colorScheme.primary;
    final organizerFirstName = _getFirstName(event.organizerName);

    // Keep horizontal spacing consistent with other cards by applying outer padding
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 22),
        decoration: BoxDecoration(
          color: appBarBackgroundColor,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                // Make title flexible to avoid overflow
                Expanded(
                  child: Text(
                    event.name,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.7,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                event.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
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
              Text(
                'Organizado por Você ($organizerFirstName)',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              const Text('🎄', style: TextStyle(fontSize: 18)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(EventCardDto event) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8E6C6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  color: Color(0xFFEB9F35),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'ORÇAMENTO MÁXIMO',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF595959),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Mostrar valor máximo do presente quando definido
          if (event.maxGiftValue != null) ...[
            Row(
              children: [
                const Text(
                  'Valor do presente: ',
                  style: TextStyle(
                    fontSize: 18,
                    color: Color(0xFF3D3D3D),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
                        .format(event.maxGiftValue),
                    style: const TextStyle(
                      fontSize: 18,
                      color: Color(0xFF1E1E1E),
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
          ] else ...[
            const SizedBox(height: 18),
          ],
          Row(
            children: [
              Expanded(
                child: _infoChip(
                  label: 'CRIADO EM',
                  value: dateFormat.format(event.createdAt),
                  color: const Color(0xFFFDE9E9),
                  textColor: const Color(0xFFBD3A3A),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _infoChip(
                  label: 'SORTEIO',
                  value: dateFormat.format(event.drawDate),
                  color: const Color(0xFFEAF5EC),
                  textColor: const Color(0xFF2E8A4A),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _infoChip(
                  label: 'FESTA',
                  value: dateFormat.format(event.eventDate),
                  color: const Color(0xFFE9F3FA),
                  textColor: const Color(0xFF2C6F9F),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip({
    required String label,
    required String value,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevealBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFDF3A4A),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
                children: [
                  TextSpan(text: 'O Sorteio Já Aconteceu!\n'),
                  TextSpan(
                    text:
                        'Clique para revelar o seu amigo secreto.',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFFF7C74B),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.card_giftcard_rounded,
              color: Color(0xFFCB4A2A),
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDADADA)),
      ),
      child: const Row(
        children: [
          Icon(Icons.search, color: Color(0xFF5C5C5C)),
          SizedBox(width: 10),
          Expanded(
            child: TextField(
              enabled: false,
              decoration: InputDecoration(
                hintText: 'Buscar participante...',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantItem({
    required String name,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required Color badgeTextColor,
    required bool showChevron,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person, color: Color(0xFF667085)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Color(0xFF1B1B1B),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badge,
              style: TextStyle(
                color: badgeTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          if (showChevron) ...[
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Color(0xFF707070)),
          ],
        ],
      ),
    );
  }
}
