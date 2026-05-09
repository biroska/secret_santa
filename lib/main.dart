import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/secret_santa_app.dart';
import 'features/auth/data/google_auth_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    final authService = GoogleAuthService();
    await authService.init();
    runApp(SecretSantaApp(auth: authService));
  } catch (e) {
    if (kDebugMode) {
      print('Erro fatal durante a inicialização: $e');
    }
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Erro ao inicializar o aplicativo:\n$e\n\n'
                'Verifique se as configurações do Firebase para Web foram aplicadas.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
