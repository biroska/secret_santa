/// Google OAuth configuration.
///
/// For Android, set [serverClientId] (Web client ID from Google Cloud Console)
/// so [GoogleSignInAuthentication.idToken] is issued reliably:
/// `--dart-define=GOOGLE_SERVER_CLIENT_ID=xxx.apps.googleusercontent.com`
class GoogleAuthConfig {
  GoogleAuthConfig._();

  static const String serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );

  static String? get serverClientIdOrNull =>
      serverClientId.isEmpty ? null : serverClientId;
}
