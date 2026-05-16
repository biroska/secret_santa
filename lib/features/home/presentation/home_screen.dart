import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart'; // Para formatação de data

import '../../../utils/app_routes.dart';
import '../../auth/data/google_auth_api.dart';
import '../../auth/data/google_auth_result.dart';
import '../../../dtos/event_card_dto.dart'; // Importando o DTO

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.auth,
    required this.session,
  });

  final GoogleAuthApi auth;
  final GoogleAuthResult session;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _signingOut = false;

  // Lista de eventos mockados
  final List<EventCardDto> mockEvents = [
    EventCardDto(
      name: 'Amigo Secreto da Empresa',
      eventDate: DateTime(2024, 12, 25),
      drawDate: DateTime(2024, 12, 10),
      icon: Icons.business,
    ),
    EventCardDto(
      name: 'Natal em Família',
      eventDate: DateTime(2024, 12, 24),
      drawDate: DateTime(2024, 12, 5),
      icon: Icons.family_restroom,
    ),
    EventCardDto(
      name: 'Confraternização Amigos',
      eventDate: DateTime(2024, 12, 30),
      drawDate: DateTime(2024, 12, 15),
      icon: Icons.people,
    ),
    EventCardDto(
      name: 'Amigo Secreto da Faculdade',
      eventDate: DateTime(2024, 12, 20),
      drawDate: DateTime(2024, 12, 1),
      icon: Icons.school,
    ),
  ];

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
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Aumentado o padding horizontal
        itemCount: mockEvents.length,
        itemBuilder: (context, index) {
          final event = mockEvents[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            child: InkWell( // Adicionado InkWell para tornar o card clicável
              onTap: () {
                context.go('/group-details'); // Navega para a tela de detalhes do grupo
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
      // FloatingActionButton removido
    );
  }
}