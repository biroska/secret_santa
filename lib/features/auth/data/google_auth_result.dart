/// Snapshot after a successful Google + Firebase sign-in.
class GoogleAuthResult {
  const GoogleAuthResult({
    required this.firebaseUid,
    required this.email,
    this.googleUserId,
    this.displayName,
    this.photoUrl,
    this.idToken,
    this.accessToken,
  });

  /// Firebase Auth user id (`User.uid`).
  final String firebaseUid;

  /// Google account id from [GoogleSignInAccount.id], if needed for diagnostics.
  final String? googleUserId;

  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? idToken;
  final String? accessToken;
}
