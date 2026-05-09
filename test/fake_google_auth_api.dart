import 'package:secret_santa/features/auth/data/google_auth_api.dart';
import 'package:secret_santa/features/auth/data/google_auth_result.dart';

class FakeGoogleAuthApi implements GoogleAuthApi {
  @override
  Future<void> init() async {}

  @override
  Future<GoogleAuthResult?> signInWithGoogle() async {
    return const GoogleAuthResult(
      firebaseUid: 'test-firebase-uid',
      email: 'test@example.com',
      displayName: 'Test User',
      googleUserId: 'test-google-id',
      idToken: 'fake-id-token',
    );
  }

  @override
  Future<void> signOut() async {}
}
