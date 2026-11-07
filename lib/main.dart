import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/secret_santa_app.dart';
import 'features/auth/data/google_auth_service.dart';
import 'theme/app_theme.dart';
// import 'services/firestore/event_service.dart'; // Removendo a importação do EventService
import 'firebase_options.dart';
import 'services/notifications/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(
    const [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
  );

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    }

    final authService = GoogleAuthService();
    await authService.init();

    try {
      await PushNotificationService.instance.initialize();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Falha ao inicializar push notifications: $e\n$st');
      }
    }

    runApp(SecretSantaApp(auth: authService));
  } catch (e) {
    if (kDebugMode) {
      print('Erro fatal durante a inicialização: $e');
    }
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Builder(
                builder: (context) => Text(
                  'Erro ao inicializar o aplicativo:\n$e\n\n'
                  'Verifique se as configurações do Firebase para Web foram aplicadas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
