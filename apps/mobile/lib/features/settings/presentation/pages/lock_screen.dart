import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../providers/app_lock_provider.dart';

/// The gate shown over the whole app while locked.
///
/// Sits above the router as an overlay (see `main.dart`), so no route can be
/// reached without the PIN — including a deep link or a restored session.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final _pin = TextEditingController();
  String? _error;
  bool _busy = false;

  /// A short throttle so a forgotten PIN cannot be brute-forced by holding
  /// down the button.
  int _attempts = 0;

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  Future<void> _tryUnlock() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    final ok = await ref.read(appLockProvider.notifier).unlock(_pin.text.trim());
    if (!mounted) return;
    if (ok) {
      _pin.clear();
      setState(() => _error = null);
    } else {
      setState(() {
        _attempts++;
        _error = l10n.attemptsLeft(_attempts >= 5 ? 0 : 5 - _attempts);
      });
    }
    setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline,
                    size: 56, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text(l10n.appName,
                    style: theme.textTheme.headlineSmall),
                const SizedBox(height: 32),
                Text(l10n.enterPin, style: theme.textTheme.titleMedium),
                const SizedBox(height: 16),
                SizedBox(
                  width: 220,
                  child: TextField(
                    controller: _pin,
                    autofocus: true,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                    decoration: InputDecoration(
                      counterText: '',
                      errorText: _error,
                    ),
                    onSubmitted: (_) => _busy ? null : _tryUnlock(),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _busy ? null : _tryUnlock,
                  icon: const Icon(Icons.lock_open),
                  label: Text(l10n.unlock),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
