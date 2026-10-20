import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/l10n/calendar_provider.dart';
import 'core/l10n/locale_provider.dart';
import 'core/onboarding/onboarding_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/presentation/providers/auth_providers.dart';
import 'features/settings/presentation/pages/lock_screen.dart';
import 'features/settings/presentation/providers/app_lock_provider.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Language and calendar are device preferences: read them before the first
  // frame so the app never opens in English and flips to Nepali (or AD and
  // flips to BS) a moment later.
  final localeController = LocaleController();
  await localeController.load();
  final calendarController = CalendarController();
  await calendarController.load();
  // Whether the first-run tour was already dismissed decides between
  // `/welcome` and `/login` in the router's first redirect — read it before
  // the first frame so the wrong screen never flashes.
  final onboardingController = OnboardingController();
  await onboardingController.load();

  runApp(
    ProviderScope(
      overrides: [
        localeProvider.overrideWith((ref) => localeController),
        calendarProvider.overrideWith((ref) => calendarController),
        onboardingSeenProvider.overrideWith((ref) => onboardingController),
      ],
      child: const KhataApp(),
    ),
  );
}

class KhataApp extends ConsumerStatefulWidget {
  const KhataApp({super.key});

  @override
  ConsumerState<KhataApp> createState() => _KhataAppState();
}

class _KhataAppState extends ConsumerState<KhataApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Resolve whether a PIN exists before the first frame, so the lock gate
    // never flashes open on a device that should be locked.
    Future.microtask(() => ref.read(appLockProvider.notifier).load());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Backgrounding is the moment a shopkeeper hands the phone to someone:
    // engage the lock so the khata is not one tap away.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      ref.read(appLockProvider.notifier).lock();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final locked = ref.watch(appLockProvider).isLocked;

    // The account carries the language the user picked on another device (or
    // before a reinstall). Apply it the moment a session becomes available;
    // a language chosen in this session is never overridden, because that is
    // only ever followed by a profile update carrying the same value.
    ref.listen(authStateProvider, (previous, next) {
      if (previous is! AuthAuthenticated && next is AuthAuthenticated) {
        ref.read(localeProvider.notifier).applyUserLocale(next.user.locale);
      }
    });

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      locale: locale,
      supportedLocales: appLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      // The lock sits above the router as an overlay: no route — including a
      // restored session or a deep link — is reachable without the PIN.
      builder: (context, child) => Stack(
        children: [
          child ?? const SizedBox.shrink(),
          if (locked) const LockScreen(),
        ],
      ),
    );
  }
}
