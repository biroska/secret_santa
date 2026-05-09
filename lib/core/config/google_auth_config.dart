/// Google OAuth configuration.
///
/// For Android, set [serverClientId] (Web client ID from Google Cloud Console)
/// so [GoogleSignInAuthentication.idToken] is issued reliably:
/// `--dart-define=GOOGLE_SERVER_CLIENT_ID=xxx.apps.googleusercontent.com`
class GoogleAuthConfig {
  GoogleAuthConfig._();

  static const String serverClientId = String.fromEnvironment(
    '786022998658-5k93l3nmnovgn4sh8443n85ij501e9t9',
    defaultValue: '',
  );

  /// On Web, this is mandatory for Google Sign-In.
  // static const String clientId = String.fromEnvironment(
  //   '786022998658-5k93l3nmnovgn4sh8443n85ij501e9t9.apps.googleusercontent.com',
  //   defaultValue: '',
  // );

  static const String clientId =  '786022998658-5k93l3nmnovgn4sh8443n85ij501e9t9.apps.googleusercontent.com';

  static String? get serverClientIdOrNull =>
      serverClientId.isEmpty ? null : serverClientId;

  static String? get clientIdOrNull => clientId.isEmpty ? null : clientId;
}
