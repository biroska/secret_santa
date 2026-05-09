import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/config/google_auth_config.dart';
import 'google_auth_api.dart';
import 'google_auth_result.dart';

/// Google Sign-In followed by [FirebaseAuth.signInWithCredential].
class GoogleAuthService implements GoogleAuthApi {
  GoogleAuthService({
    GoogleSignIn? googleSignIn,
    FirebaseAuth? firebaseAuth,
  })  : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              clientId: GoogleAuthConfig.clientIdOrNull,
              scopes: const <String>[
                'email',
                'profile',
                'https://www.googleapis.com/auth/userinfo.profile',
              ],
              serverClientId: GoogleAuthConfig.serverClientIdOrNull,
            ),
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn;
  final FirebaseAuth _firebaseAuth;

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
      final googleAuth = await account.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );
      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );
      final user = userCredential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'null-user',
          message: 'Firebase Auth returned no user after Google sign-in.',
        );
      }

      return GoogleAuthResult(
        firebaseUid: user.uid,
        googleUserId: account.id,
        email: user.email ?? account.email,
        displayName: user.displayName ?? account.displayName,
        photoUrl: user.photoURL ?? account.photoUrl,
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );
    } on FirebaseAuthException {
      rethrow;
    } on PlatformException catch (e, st) {
      if (kDebugMode) {
        debugPrint('Google sign-in failed: $e\n$st');
      }
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Firebase signOut: $e\n$st');
      }
    }
    try {
      await _googleSignIn.signOut();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Google signOut: $e\n$st');
      }
    }
  }
}
