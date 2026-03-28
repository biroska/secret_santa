import 'package:flutter/material.dart';

import 'app/secret_santa_app.dart';
import 'features/auth/data/google_auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authService = GoogleAuthService();
  await authService.init();
  runApp(SecretSantaApp(auth: authService));
}
