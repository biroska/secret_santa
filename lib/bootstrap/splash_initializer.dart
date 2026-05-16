/// Simulates app initialization work (e.g. loading config, caches) before the main UI.
class SplashInitializer {
  SplashInitializer._();

  static const Duration minimumSplashDuration = Duration(seconds: 5);

  static Future<void> simulateInitializationDelay() async {
    await Future<void>.delayed(minimumSplashDuration);
  }
}
