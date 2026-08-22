import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../dtos/event_card_dto.dart';
import '../../../../models/event.dart';
import 'mock/detalhes_evento_mock_data.dart';

const _headerGreen = Color(0xFF064E3B);
const _headerGreenLight = Color(0xFF065F46);
const _drawCardRed = Color(0xFFE11D48);
const _revealButtonYellow = Color(0xFFFACC15);
const _textNavy = Color(0xFF1E293B);
const _backgroundGray = Color(0xFFF1F5F9);

class DetalhesEventoMockScreen extends StatefulWidget {
  const DetalhesEventoMockScreen({super.key});

  @override
  State<DetalhesEventoMockScreen> createState() =>
      _DetalhesEventoMockScreenState();
}

class _DetalhesEventoMockScreenState extends State<DetalhesEventoMockScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MockParticipantEntry> get _filteredParticipants {
    if (_searchQuery.isEmpty) return DetalhesEventoMockData.participants;
    return DetalhesEventoMockData.participants
        .where((e) => e.displayName.toLowerCase().contains(_searchQuery))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final eventCard = DetalhesEventoMockData.eventCard;
    final event = DetalhesEventoMockData.event;
    final participants = _filteredParticipants;

    return Scaffold(
      backgroundColor: _backgroundGray,
      body: Column(
        children: [
          _MockHeader(eventCard: eventCard),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                Transform.translate(
                  offset: const Offset(0, -24),
                  child: _EventInfoCard(
                    eventCard: eventCard,
                    event: event,
                    maxBudget: DetalhesEventoMockData.maxBudget,
                  ),
                ),
                if (event.status == 'DRAWN') ...[
                  const SizedBox(height: 8),
                  const _DrawRevealCard(),
                ],
                const SizedBox(height: 24),
                _ParticipantsSectionHeader(
                  count: DetalhesEventoMockData.participants.length,
                ),
                const SizedBox(height: 12),
                _SearchField(controller: _searchController),
                const SizedBox(height: 12),
                ...participants.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ParticipantTile(entry: entry),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MockHeader extends StatelessWidget {
  const _MockHeader({required this.eventCard});

  final EventCardDto eventCard;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_headerGreen, _headerGreenLight],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _CircleIconButton(
                    icon: Icons.arrow_back_ios_new,
                    onPressed: () => context.pop(),
                  ),
                  const Expanded(
                    child: Text(
                      'DETALHES',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF6EE7B7),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const _CircleIconButton(icon: Icons.more_vert),
                ],
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  eventCard.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Color(0xFF34D399),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Organizado por Você (${eventCard.organizerName})',
                      style: const TextStyle(
                        color: Color(0xFF6EE7B7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.15),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _EventInfoCard extends StatelessWidget {
  const _EventInfoCard({
    required this.eventCard,
    required this.event,
    required this.maxBudget,
  });

  final EventCardDto eventCard;
  final Events event;
  final double maxBudget;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final budgetFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF9C3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.card_giftcard,
                  color: Color(0xFFEAB308),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ORÇAMENTO MÁXIMO',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Até ${budgetFormat.format(maxBudget)}',
                      style: const TextStyle(
                        color: _textNavy,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade200, height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _DateChip(
                  label: 'CRIADO EM',
                  date: dateFormat.format(event.createdAt),
                  labelColor: Colors.grey.shade500,
                  dateColor: _textNavy,
                  backgroundColor: const Color(0xFFF1F5F9),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DateChip(
                  label: 'SORTEIO',
                  date: dateFormat.format(eventCard.drawDate),
                  labelColor: const Color(0xFFEC4899),
                  dateColor: const Color(0xFFDB2777),
                  backgroundColor: const Color(0xFFFCE7F3),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DateChip(
                  label: 'FESTA',
                  date: dateFormat.format(eventCard.eventDate),
                  labelColor: const Color(0xFF059669),
                  dateColor: const Color(0xFF047857),
                  backgroundColor: const Color(0xFFD1FAE5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.label,
    required this.date,
    required this.labelColor,
    required this.dateColor,
    required this.backgroundColor,
  });

  final String label;
  final String date;
  final Color labelColor;
  final Color dateColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            date,
            style: TextStyle(
              color: dateColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DrawRevealCard extends StatelessWidget {
  const _DrawRevealCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFBE123C), _drawCardRed],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'O Sorteio Já Aconteceu! 🎉',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Clique para revelar em uma animação mágica quem é o seu amigo secreto.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _revealButtonYellow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.visibility, color: _textNavy, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Revelar Meu Amigo',
                        style: TextStyle(
                          color: _textNavy,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(
              Icons.card_giftcard,
              size: 100,
              color: _revealButtonYellow.withValues(alpha: 0.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticipantsSectionHeader extends StatelessWidget {
  const _ParticipantsSectionHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Participantes',
          style: TextStyle(
            color: _textNavy,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Color(0xFFD1FAE5),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$count',
              style: const TextStyle(
                color: Color(0xFF059669),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const Spacer(),
        const Row(
          children: [
            Icon(Icons.add, color: _headerGreen, size: 20),
            SizedBox(width: 4),
            Text(
              'Convidar',
              style: TextStyle(
                color: _headerGreen,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Buscar participante...',
        hintStyle: TextStyle(color: Colors.grey.shade400),
        prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  const _ParticipantTile({required this.entry});

  final MockParticipantEntry entry;

  @override
  Widget build(BuildContext context) {
    final name = entry.isCurrentUser
        ? '${entry.displayName} (Você)'
        : entry.displayName;
    final wishCount = entry.participant.giftWish.length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey.shade200,
            child: Icon(Icons.person, color: Colors.grey.shade400),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: _textNavy,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$wishCount desejos cadastrados',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _RoleBadge(role: entry.participant.role),
          Icon(Icons.chevron_right, color: Colors.grey.shade400),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    if (role == 'ORG') {
      return Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF059669),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'ORG',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFDBEAFE),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'Confirmado',
        style: TextStyle(
          color: Color(0xFF2563EB),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
