import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../dtos/event_card_dto.dart';
import '../../../services/firestore/event_service.dart';
import 'adicionar_pessoa_screen.dart';
import 'event_title_card.dart';

class EventDetailsScreen extends StatefulWidget {
  final String eventId;

  const EventDetailsScreen({super.key, required this.eventId});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  late final EventService _eventService;
  Future<EventCardDto?>? _eventFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isFriendRevealVisible = false;

  @override
  void initState() {
    super.initState();
    _eventService = EventService();
    _fetchEventDetails();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      _isFriendRevealVisible = false;
      _eventFuture = _eventService.getEventById(widget.eventId);
    });
  }

  Future<void> _refreshEventDetails() async {
    try {
      setState(() {
        _isFriendRevealVisible = false;
      });
      final refreshedEvent = await _eventService.getEventById(widget.eventId);
      if (!mounted) return;

      setState(() {
        _eventFuture = Future.value(refreshedEvent);
      });

      if (refreshedEvent == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível atualizar os participantes no momento.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar os dados do evento: $e')),
      );
    }
  }

  Future<void> _confirmDeleteEvent(
    BuildContext context,
    EventCardDto event,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir evento?'),
        content: Text(
          'Você está prestes a remover o evento "${event.name}". Essa ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _eventService.deleteEvent(event.id);
      if (!context.mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível excluir o evento: $e')),
      );
    }
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
        final filteredParticipants = _filteredParticipants(event);
        final hasSearchQuery = _searchQuery.trim().isNotEmpty;
        final shouldShowRevealBanner =
            event.drawDate != null && event.drawDate!.isBefore(DateTime.now());
        final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
        final isAdmin =
            currentUserId.isNotEmpty && currentUserId == event.adminId;
        final revealedParticipant = _getLastParticipant(event.participants);
        final shouldShowRevealedParticipantCard =
            shouldShowRevealBanner && _isFriendRevealVisible;

        return Scaffold(
          backgroundColor: const Color(0xFFF2F3F5),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _refreshEventDetails,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildHeader(context, event, isAdmin),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSummaryCard(event),
                          const SizedBox(height: 18),
                          if (isAdmin &&
                              !shouldShowRevealBanner &&
                              event.participants.length >= 3)
                            _buildAdminDrawCard(),
                          if (isAdmin &&
                              !shouldShowRevealBanner &&
                              event.participants.length >= 3)
                            const SizedBox(height: 24),
                          if (shouldShowRevealBanner &&
                              !shouldShowRevealedParticipantCard)
                            _buildRevealBanner(),
                          if (shouldShowRevealBanner &&
                              shouldShowRevealedParticipantCard)
                            _buildRevealedParticipantCard(revealedParticipant),
                          if (shouldShowRevealBanner)
                            const SizedBox(height: 24),
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
                                '${event.participants.length}',
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const Spacer(),
                              if (!shouldShowRevealBanner)
                                TextButton.icon(
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => AdicionarPessoaScreen(
                                        eventId: widget.eventId,
                                      ),
                                    ),
                                  ),
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
                          if (filteredParticipants.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: Text(
                                hasSearchQuery
                                    ? 'Nenhum participante encontrado'
                                    : 'Nenhum participante ainda',
                                style: const TextStyle(
                                  color: Color(0xFF667085),
                                ),
                              ),
                            )
                          else
                            Column(
                              children: filteredParticipants.map((p) {
                                final rawName =
                                    (p['name'] as String?)?.trim() ??
                                    (p['userId'] as String? ?? 'Usuário');
                                final name = _getFirstName(rawName);
                                final role = ((p['role'] as String?) ?? '')
                                    .toUpperCase();
                                String badgeLabel;
                                Color badgeColor;
                                Color badgeTextColor;

                                if (role == 'ADMIN') {
                                  badgeLabel = 'Organizador';
                                  badgeColor = const Color(0xFFD9E9E6);
                                  badgeTextColor = const Color(0xFF1D7B72);
                                } else if (role == 'DEPENDENT' ||
                                    role == 'DEPENDENT') {
                                  badgeLabel = 'Dependente';
                                  badgeColor = const Color(0xFFE9F3FA);
                                  badgeTextColor = const Color(0xFF2C6F9F);
                                } else {
                                  badgeLabel = 'Participante';
                                  badgeColor = const Color(0xFFE2F0E2);
                                  badgeTextColor = const Color(0xFF3D8F3D);
                                }

                                final photoUrl =
                                    (p['photoUrl'] as String?) ?? '';

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildParticipantItem(
                                    name: name,
                                    subtitle: '3 desejos cadastrados',
                                    badge: badgeLabel,
                                    badgeColor: badgeColor,
                                    badgeTextColor: badgeTextColor,
                                    showBadge: true,
                                    avatarUrl: photoUrl.isNotEmpty
                                        ? photoUrl
                                        : null,
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _filteredParticipants(EventCardDto event) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return event.participants;
    }

    return event.participants.where((participant) {
      final name =
          ((participant['name'] as String?) ??
                  (participant['userId'] as String?) ??
                  '')
              .toString()
              .trim();
      final userId = ((participant['userId'] as String?) ?? '')
          .toString()
          .trim();
      return name.toLowerCase().contains(query) ||
          userId.toLowerCase().contains(query);
    }).toList();
  }

  Map<String, dynamic>? _getLastParticipant(
    List<Map<String, dynamic>> participants,
  ) {
    if (participants.isEmpty) {
      return null;
    }

    return participants.last;
  }

  String _getFirstName(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return 'Você';
    }

    final parts = normalized
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return normalized;
    }
    if (parts.length == 1) {
      return parts.first;
    }

    return '${parts[0]} ${parts[1]}';
  }

  // DEV helper: insere todos usuários da coleção 'users' como participantes do evento
  // Usa EventService.addParticipantIfNotExists para evitar duplicatas.
  Future<void> _devAddAllUsersToParticipants(BuildContext context) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final usersSnap = await firestore.collection('users').get();
      if (usersSnap.docs.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nenhum usuário encontrado na coleção users.'),
          ),
        );
        return;
      }

      for (var doc in usersSnap.docs) {
        final uid = doc.id;
        try {
          await _eventService.addParticipantIfNotExists(widget.eventId, uid);
        } catch (e) {
          debugPrint('Falha ao processar usuário $uid: $e');
        }
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Processados ${usersSnap.docs.length} usuários.'),
        ),
      );

      // Recarregar detalhes do evento para refletir alterações
      _fetchEventDetails();
    } catch (e) {
      debugPrint('Erro devAddAllUsers: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao adicionar usuários: $e')));
    }
  }

  Widget _buildHeader(BuildContext context, EventCardDto event, bool isAdmin) {
    final appBarBackgroundColor =
        Theme.of(context).appBarTheme.backgroundColor ??
        Theme.of(context).colorScheme.primary;

    return EventTitleCard(
      event: event,
      isAdmin: isAdmin,
      onBack: () => Navigator.of(context).pop(),
      onDelete: () => _confirmDeleteEvent(context, event),
      onDevAddAll: () => _devAddAllUsersToParticipants(context),
      backgroundColor: appBarBackgroundColor,
    );
  }

  Widget _buildSummaryCard(EventCardDto event) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    final giftValueLabel = event.maxGiftValue != null
        ? NumberFormat.currency(
            locale: 'pt_BR',
            symbol: 'R\$',
          ).format(event.maxGiftValue)
        : 'Livre';
    final drawDateLabel = event.drawDate != null
        ? dateFormat.format(event.drawDate!)
        : 'Não realizado';
    final eventDateLabel = event.eventDate != null
        ? dateFormat.format(event.eventDate!)
        : 'A definir';

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
                  'Valor do presente: $giftValueLabel',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF595959),
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
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
                  value: drawDateLabel,
                  color: const Color(0xFFEAF5EC),
                  textColor: const Color(0xFF2E8A4A),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _infoChip(
                  label: 'FESTA',
                  value: eventDateLabel,
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

  Future<void> _showDrawConfirmationDialog() async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final shouldContinue = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Realizar sorteio?'),
        content: const Text(
          'Após confirmar o sorteio, o evento não poderá ser alterado. Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (shouldContinue != true || !mounted) return;

    try {
      await _eventService.updateDrawDate(widget.eventId);
      if (!mounted) return;
      await _refreshEventDetails();
      messenger?.showSnackBar(
        const SnackBar(content: Text('Sorteio confirmado com sucesso.')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger?.showSnackBar(
        SnackBar(content: Text('Não foi possível confirmar o sorteio: $e')),
      );
    }
  }

  Future<bool> _confirmRevealWithPassword() async {
    final passwordController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmação de senha'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Senha do celular',
            hintText: 'Digite sua senha',
          ),
          keyboardType: TextInputType.visiblePassword,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final value = passwordController.text.trim();
              Navigator.of(dialogContext).pop(value.isNotEmpty);
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    return confirmed == true;
  }

  Widget _buildAdminDrawCard() {
    return InkWell(
      onTap: _showDrawConfirmationDialog,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF5EC),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Expanded(
              child: RichText(
                text: const TextSpan(
                  style: TextStyle(
                    color: Color(0xFF2E8A4A),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                  children: [
                    TextSpan(text: 'Realizar sorteio\n'),
                    TextSpan(
                      text:
                          'Atenção: após confirmar, o evento não poderá ser alterado.',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
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
                color: Color(0xFF2E8A4A),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.card_giftcard_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevealBanner() {
    return InkWell(
      onTap: () async {
        final confirmed = await _confirmRevealWithPassword();
        if (!mounted || !confirmed) return;
        setState(() => _isFriendRevealVisible = true);
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
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
                      text: 'Revele o seu amigo secreto',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
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
      ),
    );
  }

  Widget _buildRevealedParticipantCard(Map<String, dynamic>? participant) {
    if (participant == null) {
      return const SizedBox.shrink();
    }

    final name = _getFirstName(
      (participant['name'] as String?)?.trim() ??
          (participant['userId'] as String? ?? 'Usuário'),
    );
    final photoUrl = (participant['photoUrl'] as String?) ?? '';

    return InkWell(
      onTap: () => setState(() => _isFriendRevealVisible = false),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildParticipantItem(
          name: name,
          subtitle: 'Seu amigo secreto',
          badge: '',
          badgeColor: Colors.transparent,
          badgeTextColor: Colors.transparent,
          showBadge: false,
          avatarUrl: photoUrl.isNotEmpty ? photoUrl : null,
        ),
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
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFF5C5C5C)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              enabled: true,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: const InputDecoration(
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
    required bool showBadge,
    String? avatarUrl,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          if (avatarUrl != null && avatarUrl.isNotEmpty)
            CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(avatarUrl),
              backgroundColor: const Color(0xFFE5E7EB),
            )
          else
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
          if (showBadge)
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
        ],
      ),
    );
  }
}
