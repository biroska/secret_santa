import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/about/presentation/about_screen.dart';
import '../features/auth/data/google_auth_api.dart';
import '../features/auth/data/google_auth_result.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/group/presentation/create_group_screen.dart';
import '../features/group/presentation/group_details_screen.dart';
import '../features/events/presentation/create_event_screen.dart';
import '../features/events/presentation/scan_invite_screen.dart';
import '../features/events/presentation/event_details_screen.dart';
import '../features/events/presentation/event_invite_screen.dart';
import '../features/events/presentation/incluir_dependente_screen.dart';
import '../theme/app_theme.dart';
import '../services/firestore/event_service.dart';
import 'app_keys.dart';

class SecretSantaApp extends StatefulWidget {
  const SecretSantaApp({super.key, required this.auth});

  final GoogleAuthApi auth;

  @override
  State<SecretSantaApp> createState() => _SecretSantaAppState();
}

class _SecretSantaAppState extends State<SecretSantaApp> {
  late final GoRouter _router;
  late final EventService _eventService;

  @override
  void initState() {
    super.initState();
    final auth = widget.auth;
    _eventService = EventService();
    _router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) {
            final pendingEventId = state.uri.queryParameters['invite'];
            return LoginScreen(auth: auth, pendingEventId: pendingEventId);
          },
        ),
        GoRoute(
          path: '/home',
          redirect: (context, state) {
            if (state.extra is GoogleAuthResult) {
              return null;
            }

            final firebaseUser = FirebaseAuth.instance.currentUser;
            if (firebaseUser == null) {
              return '/login';
            }

            return null;
          },
          builder: (context, state) {
            final session = state.extra is GoogleAuthResult
                ? state.extra as GoogleAuthResult
                : GoogleAuthResult(
                    firebaseUid: FirebaseAuth.instance.currentUser?.uid ?? '',
                    email: FirebaseAuth.instance.currentUser?.email ?? '',
                    displayName: FirebaseAuth.instance.currentUser?.displayName,
                    photoUrl: FirebaseAuth.instance.currentUser?.photoURL,
                  );

            return HomeScreen(
              auth: auth,
              session: session,
              eventService: _eventService,
            );
          },
        ),
        GoRoute(
          path: '/about',
          builder: (context, state) => const AboutScreen(),
        ),
        GoRoute(
          path: '/create-group',
          builder: (context, state) => const CreateGroupScreen(),
        ),
        GoRoute(
          path: '/group-details',
          builder: (context, state) => const GroupDetailsScreen(),
        ),
        GoRoute(
          path: '/create-event',
          builder: (context, state) => CreateEventScreen(eventService: _eventService), // Passando o eventService
        ),
        GoRoute(
          // Deep link de convite: secretsanta://invite/<eventId>
          path: '/invite/:eventId',
          redirect: (context, state) {
            if (FirebaseAuth.instance.currentUser == null) {
              final eventId = state.pathParameters['eventId'] ?? '';
              return '/login?invite=${Uri.encodeComponent(eventId)}';
            }
            return null;
          },
          builder: (context, state) {
            final eventId = state.pathParameters['eventId'] ?? '';
            return EventInviteScreen(eventId: eventId, eventService: _eventService);
          },
        ),
        GoRoute(
          // Android App Link: https://galdinos-secret-santa.web.app/event/<eventId>
          // e fallback custom scheme: secretsanta://event/<eventId>
          path: '/event/:eventId',
          redirect: (context, state) {
            if (FirebaseAuth.instance.currentUser == null) {
              final eventId = state.pathParameters['eventId'] ?? '';
              return '/login?invite=${Uri.encodeComponent(eventId)}';
            }
            return null;
          },
          builder: (context, state) {
            final eventId = state.pathParameters['eventId'] ?? '';
            return EventInviteScreen(eventId: eventId, eventService: _eventService);
          },
        ),
        GoRoute(
          path: '/scan-invite',
          builder: (context, state) => const ScanInviteScreen(),
        ),
        GoRoute(
          path: '/event-details/:id',
          builder: (context, state) {
            final eventId = state.pathParameters['id']!;
            return EventDetailsScreen(eventId: eventId);
          },
        ),
        GoRoute(
          path: '/event-dependent',
          builder: (context, state) {
            final participants = state.extra is List<Map<String, dynamic>>
                ? state.extra as List<Map<String, dynamic>>
                : const <Map<String, dynamic>>[];
            final eventId = state.pathParameters['id'] ??
                (state.extra is Map ? (state.extra as Map)['eventId']?.toString() ?? '' : '');
            return IncluirDependenteScreen(
              eventId: eventId,
              eventParticipants: participants,
            );
          },
        ),
      ],
      // Cobre deep links malformados/rotas desconhecidas (ex.: link de convite
      // com path inexistente), redirecionando para a Home com uma notificação.
      errorBuilder: (context, state) => const _UnknownDeepLinkScreen(),
    );
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Secret Santa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      routerConfig: _router,
    );
  }
}

/// Tela exibida quando o GoRouter não encontra nenhuma rota compatível com o
/// deep link recebido (ex.: path inexistente/mal formado). Redireciona para a
/// Home e notifica o usuário assim que o primeiro frame é renderizado.
class _UnknownDeepLinkScreen extends StatefulWidget {
  const _UnknownDeepLinkScreen();

  @override
  State<_UnknownDeepLinkScreen> createState() => _UnknownDeepLinkScreenState();
}

class _UnknownDeepLinkScreenState extends State<_UnknownDeepLinkScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go('/home');
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Evento não encontrado.')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}