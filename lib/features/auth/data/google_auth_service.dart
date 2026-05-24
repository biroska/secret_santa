import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/config/google_auth_config.dart';
import 'google_auth_api.dart';
import 'google_auth_result.dart';
import '../../../services/firestore/user_service.dart'; // Importando UserService
import '../../../models/user.dart'; // Importando a classe Users

/// Google Sign-In followed by [FirebaseAuth.signInWithCredential].
class GoogleAuthService implements GoogleAuthApi {
  final UserService _userService; // Adicionando UserService

  GoogleAuthService({
    GoogleSignIn? googleSignIn,
    FirebaseAuth? firebaseAuth,
    UserService? userService, // Adicionando userService ao construtor
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
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _userService = userService ?? UserService(); // Inicializando UserService

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

      // --- Nova lógica para verificar e criar usuário no Firestore ---
      final userExistsInFirestore = await _userService.userExists(user.uid);
      if (!userExistsInFirestore) {
        final newUser = Users( // Usando a classe Users
          id: user.uid,
          name: user.displayName ?? user.email!, // Usando displayName ou email como name
          email: user.email!,
          photoUrl: user.photoURL ?? '', // photoURL pode ser null, então forneça um fallback
          createdAt: DateTime.now(),
        );
        await _userService.createUser(newUser);
      }
      // --- Fim da nova lógica ---

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