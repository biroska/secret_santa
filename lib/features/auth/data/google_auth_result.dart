/// Snapshot after a successful Google Sign-In (for UI or backend handoff).
class GoogleAuthResult {
  const GoogleAuthResult({
    required this.userId,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.idToken,
    this.accessToken,
  });

  final String userId;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? idToken;
  final String? accessToken;
}
