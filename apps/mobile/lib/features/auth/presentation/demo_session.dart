import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import 'providers/auth_providers.dart';

/// True when this build was compiled with demo credentials
/// (`--dart-define=DEMO_EMAIL=… --dart-define=DEMO_PASSWORD=…`).
///
/// The credentials never live in source, and a production build simply has no
/// "Try the demo" button because both values are empty.
bool get demoAvailable =>
    AppConfig.demoEmail.isNotEmpty && AppConfig.demoPassword.isNotEmpty;

/// Signs into the shared demo shop.
///
/// Navigation is not done here: the router's redirect sends an authenticated
/// session away from `/login` and `/welcome` on its own, which keeps one
/// definition of "where does a signed-in user go".
Future<void> startDemoSession(WidgetRef ref) {
  return ref.read(authStateProvider.notifier).login(
        email: AppConfig.demoEmail,
        password: AppConfig.demoPassword,
      );
}
