import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/data/google_auth_api.dart';
import '../features/auth/data/google_auth_result.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/group/presentation/create_group_screen.dart';
import '../features/group/presentation/group_details_screen.dart'; // Importando a nova tela de detalhes
import '../theme/app_theme.dart';

class SecretSantaApp extends StatefulWidget {
  const SecretSantaApp({super.key, required this.auth});

  final GoogleAuthApi auth;

  @override
  State<SecretSantaApp> createState() => _SecretSantaAppState();
}

class _SecretSantaAppState extends State<SecretSantaApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final auth = widget.auth;
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
            return HomeScreen(auth: auth, session: session);
          },
        ),
        GoRoute(
          path: '/create-group',
          builder: (context, state) => const CreateGroupScreen(),
        ),
        GoRoute(
          path: '/group-details', // Nova rota para detalhes do grupo
          builder: (context, state) => const GroupDetailsScreen(),
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