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
  late Future<List<EventCardDto>> _eventsFuture; // Future para carregar os eventos

  @override
  void initState() {
    super.initState();
    _eventsFuture = _loadEvents(); // Inicia o carregamento dos eventos
  }

  // Método para recarregar os eventos e atualizar o Future
  void _refreshEvents() {
    setState(() {
      _eventsFuture = _loadEvents();
    });
  }

  Future<List<EventCardDto>> _loadEvents() async {
    final rawEvents = await widget.eventService.getEvents();
    return rawEvents; // EventService já retorna List<EventCardDto>
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
      body: FutureBuilder<List<EventCardDto>>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar eventos: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhum evento encontrado.'));
          } else {
            final events = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  child: InkWell(
                    onTap: () {
                      context.go('/group-details');
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
            );
          }
        },
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