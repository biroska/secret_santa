import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/data/google_auth_api.dart';
import '../features/auth/data/google_auth_result.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/group/presentation/create_group_screen.dart';
import '../features/group/presentation/group_details_screen.dart';
import '../features/events/presentation/create_event_screen.dart';
import '../features/events/presentation/event_details_screen.dart';
import '../features/events/presentation/incluir_dependente_screen.dart';
import '../theme/app_theme.dart';
import '../services/firestore/event_service.dart';

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
          builder: (context, state) => LoginScreen(auth: auth),
        ),
        GoRoute(
          path: '/home',
          redirect: (context, state) {
            if (state.extra is! GoogleAuthResult) {
              return '/login';
            }
            return null;
          },
          builder: (context, state) {
            final session = state.extra! as GoogleAuthResult;
            return HomeScreen(
              auth: auth,
              session: session,
              eventService: _eventService,
            );
          },
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
            return IncluirDependenteScreen(eventParticipants: participants);
          },
        ),
      ],
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
      routerConfig: _router,
    );
  }
}