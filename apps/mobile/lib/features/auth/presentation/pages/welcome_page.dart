import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/onboarding/onboarding_provider.dart';
import '../../../../core/widgets/language_selector.dart';
import '../providers/auth_providers.dart';
import '../demo_session.dart';
import '../../../../l10n/app_localizations.dart';

/// First run: a three-slide tour, the language choice, and two ways out.
///
/// Both exits mark the tour as seen — "Skip" is not a lesser path, it is the
/// same decision made sooner. The language chips sit above the pager so they
/// are reachable on every slide, and they apply immediately: everything below
/// them re-renders in the chosen language, which is the clearest possible proof
/// that the switch worked.
class WelcomePage extends ConsumerStatefulWidget {
  const WelcomePage({super.key});

  @override
  ConsumerState<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends ConsumerState<WelcomePage> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(onboardingSeenProvider.notifier).complete();
    if (mounted) context.go('/login');
  }

  void _next() {
    if (_page >= 2) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final authState = ref.watch(authStateProvider);

    ref.listen<AuthState>(authStateProvider, (previous, next) {
      if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authErrorMessage(next.message, l10n))),
        );
      }
    });

    final slides = <(IconData, String, String)>[
      (Icons.menu_book_outlined, l10n.welcomeSlide1Title, l10n.welcomeSlide1Body),
      (Icons.inventory_2_outlined, l10n.welcomeSlide2Title, l10n.welcomeSlide2Body),
      (Icons.insights_outlined, l10n.welcomeSlide3Title, l10n.welcomeSlide3Body),
    ];

    final isLast = _page == slides.length - 1;
    final busy = authState is AuthLoading;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
              child: Row(
                children: [
                  Icon(Icons.account_balance_wallet,
                      size: 22, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.appName,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const LanguageMenuButton(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.welcomeChooseLanguage,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const LanguageChips(),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: slides.length,
                onPageChanged: (index) => setState(() => _page = index),
                itemBuilder: (context, index) => _Slide(
                  icon: slides[index].$1,
                  title: slides[index].$2,
                  body: slides[index].$3,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < slides.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 6,
                    width: i == _page ? 20 : 6,
                    decoration: BoxDecoration(
                      color: i == _page
                          ? theme.colorScheme.primary
                          : theme.colorScheme.primary.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  TextButton(
                    onPressed: busy ? null : _finish,
                    child: Text(l10n.welcomeSkip),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: busy ? null : _next,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(132, 48),
                    ),
                    child: busy
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isLast ? l10n.getStarted : l10n.next),
                  ),
                ],
              ),
            ),
            if (isLast && demoAvailable)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextButton.icon(
                  onPressed: busy ? null : () => startDemoSession(ref),
                  icon: const Icon(Icons.play_circle_outline, size: 18),
                  label: Text(l10n.tryDemo),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _Slide({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Centre the slide in the available height, but stay scrollable on a short
    // phone: a bare SingleChildScrollView pins the content to the top and
    // leaves a dead third of the screen below it.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 46, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 26),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
            ],
          ),
        ),
      ),
    );
  }
}
