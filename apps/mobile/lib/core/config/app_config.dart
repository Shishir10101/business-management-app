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
}
