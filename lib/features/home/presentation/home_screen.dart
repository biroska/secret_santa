import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart'; // Para formatação de data

import '../../../utils/app_routes.dart';
import '../../auth/data/google_auth_api.dart';
import '../../auth/data/google_auth_result.dart';
import '../../../dtos/event_card_dto.dart'; // Importando o DTO
import '../../../services/firestore/event_service.dart'; // Importando o EventService

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.auth,
    required this.session,
    required this.eventService, // Adicionando eventService ao construtor
  });

  final GoogleAuthApi auth;
  final GoogleAuthResult session;
  final EventService eventService; // Declarando eventService

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _signingOut = false;
  // Paginated events state
  final List<EventCardDto> _events = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingInitial = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  final int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitial(); // Inicia o carregamento dos eventos
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Método para recarregar os eventos (pull-to-refresh)
  Future<void> _refreshEvents() async {
    setState(() {
      _isLoadingInitial = true;
      _hasMore = true;
    });
    try {
      final fresh = await widget.eventService.getEvents();
      setState(() {
        _events
          ..clear()
          ..addAll(fresh);
        _hasMore = fresh.length >= _pageSize;
      });
    } finally {
      setState(() => _isLoadingInitial = false);
    }
  }

  Future<void> _loadInitial() async {
    setState(() => _isLoadingInitial = true);
    final page = await widget.eventService.getEventsPage(limit: _pageSize);
    setState(() {
      _events.clear();
      _events.addAll(page);
      _hasMore = page.length >= _pageSize;
      _isLoadingInitial = false;
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_events.isEmpty) return;
    setState(() => _isLoadingMore = true);
    final last = _events.last;
    final page = await widget.eventService.getEventsPage(startAfter: last.eventDate, limit: _pageSize);
    setState(() {
      _events.addAll(page);
      _hasMore = page.length >= _pageSize;
      _isLoadingMore = false;
    });
  }

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    try {
      await widget.auth.signOut();
      if (!mounted) return;
      context.go(AppRoutes.AUTH);
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = widget.session.displayName ?? widget.session.email;
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text('Bem vindo ${name.split(' ')[0]}'),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            );
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 20,
              backgroundImage: widget.session.photoUrl != null
                  ? NetworkImage(widget.session.photoUrl!)
                  : null,
              child: widget.session.photoUrl == null
                  ? const Icon(Icons.person, size: 24)
                  : null,
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: widget.session.photoUrl != null
                        ? NetworkImage(widget.session.photoUrl!)
                        : null,
                    child: widget.session.photoUrl == null
                        ? const Icon(Icons.person, size: 36, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
                  ),
                  Text(
                    widget.session.email,
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Novo Evento'),
              onTap: () async { // Alterado para async
                Navigator.pop(context); // Fecha o drawer
                final result = await context.push('/create-event'); // Aguarda o resultado
                if (result == true) { // Se o evento foi salvo com sucesso
                  _refreshEvents(); // Recarrega a lista de eventos
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text('Meus Grupos'),
              onTap: () {
                Navigator.pop(context); // Fecha o drawer
                // TODO: Implementar navegação para Meus Grupos
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configurações'),
              onTap: () {
                Navigator.pop(context); // Fecha o drawer
                // TODO: Implementar navegação para Configurações
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Sobre'),
              onTap: () {
                Navigator.pop(context); // Fecha o drawer
                // TODO: Implementar navegação para Sobre
              },
            ),
            const Divider(), // Adiciona um divisor antes do item Sair
            ListTile(
              leading: const Icon(Icons.logout),
              title: _signingOut
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Sair'),
              onTap: _signingOut ? null : _signOut,
            ),
          ],
        ),
      ),
      body: Column( // Usando Column para o botão e a lista
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded( // Expanded para a lista ocupar o espaço restante
            child: _isLoadingInitial
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _refreshEvents,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      itemCount: _events.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= _events.length) {
                          // loading more indicator
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final event = _events[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          child: InkWell(
                            onTap: () {
                              context.push('/event-details/${event.id}'); // Alterado para /event-details
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: theme.colorScheme.primaryContainer,
                                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                                    child: Icon(event.icon),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          event.name,
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Organizador: ${event.organizerName}', // Nova linha para o organizador
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Data: ${dateFormat.format(event.eventDate)} Data Sorteio: ${dateFormat.format(event.drawDate)}',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            fontStyle: FontStyle.italic,
                                            color: theme.colorScheme.onSurfaceVariant,
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
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async { // Alterado para async
          final result = await context.push('/create-event'); // Aguarda o resultado
          if (result == true) { // Se o evento foi salvo com sucesso
            _refreshEvents(); // Recarrega a lista de eventos
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}