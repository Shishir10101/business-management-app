/// Application configuration constants.
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5000',
  );

  static const String apiVersion = 'v1';
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static String get apiBase => '$apiBaseUrl/api';

  /// Optional demo shop credentials.
  ///
  /// Supplied at build time (`--dart-define=DEMO_EMAIL=…`), never in source.
  /// Empty in a normal build, which hides every "Try the demo" affordance —
  /// see `demoAvailable` in `features/auth/presentation/demo_session.dart`.
  static const String demoEmail = String.fromEnvironment('DEMO_EMAIL');
  static const String demoPassword = String.fromEnvironment('DEMO_PASSWORD');

  /// Where the app looks for a newer build.
  ///
  /// The APK is distributed as a GitHub Release asset rather than through a
  /// store, so the repository is part of the update mechanism. Overridable at
  /// build time to point a fork at its own releases.
  static const String updateRepoOwner = String.fromEnvironment(
    'UPDATE_REPO_OWNER',
    defaultValue: 'Shishir10101',
  );

  static const String updateRepoName = String.fromEnvironment(
    'UPDATE_REPO_NAME',
    defaultValue: 'business-management-app',
  );

  /// Set to `false` for store builds, where the store owns updates.
  static const bool updateCheckEnabled = bool.fromEnvironment(
    'UPDATE_CHECK_ENABLED',
    defaultValue: true,
  );
}
