import 'google_auth_result.dart';

abstract class GoogleAuthApi {
  Future<void> init();

  Future<GoogleAuthResult?> signInWithGoogle();

  Future<void> signOut();
}
