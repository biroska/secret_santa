import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/config/google_auth_config.dart';
import 'google_auth_api.dart';
import 'google_auth_result.dart';

/// Live Google Sign-In. Supported on Android, iOS, macOS, and Web — not on Windows/Linux desktop.
class GoogleAuthService implements GoogleAuthApi {
  GoogleAuthService({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: const <String>[
                'email',
                'profile',
              ],
              serverClientId: GoogleAuthConfig.serverClientIdOrNull,
            );

  final GoogleSignIn _googleSignIn;

  static bool get isPlatformSupported =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  @override
  Future<void> init() async {
    await _googleSignIn.isSignedIn();
  }

  @override
  Future<GoogleAuthResult?> signInWithGoogle() async {
    if (!isPlatformSupported) {
      throw PlatformException(
        code: 'unsupported_platform',
        message:
            'Google Sign-In is not supported on this platform. Use Android, iOS, macOS, or Web.',
      );
    }

    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        return null;
      }
      final auth = await account.authentication;
      return GoogleAuthResult(
        userId: account.id,
        email: account.email,
        displayName: account.displayName,
        photoUrl: account.photoUrl,
        idToken: auth.idToken,
        accessToken: auth.accessToken,
      );
    } on PlatformException catch (e, st) {
      if (kDebugMode) {
        debugPrint('Google sign-in failed: $e\n$st');
      }
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
