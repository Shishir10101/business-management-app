import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../providers/app_lock_provider.dart';

/// Set, change, or turn off the app-lock PIN.
///
/// Three fields are always shown but only the relevant ones are required:
/// turning the lock off asks for the current PIN; changing it asks for the
/// current and the new one; setting it for the first time needs only the new
/// one (confirmed).
class AppLockSettingsPage extends ConsumerStatefulWidget {
  const AppLockSettingsPage({super.key});

  @override
  ConsumerState<AppLockSettingsPage> createState() =>
      _AppLockSettingsPageState();
}

class _AppLockSettingsPageState extends ConsumerState<AppLockSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _newPin = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _current.dispose();
    _newPin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _isEnabled => ref.read(appLockProvider).isEnabled;

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _busy = true);
    final notifier = ref.read(appLockProvider.notifier);
    try {
      if (!_isEnabled) {
        // First-time setup.
        await notifier.setPin(_newPin.text.trim());
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.appLockNowOn)));
          Navigator.of(context).pop();
        }
      } else if (_newPin.text.isEmpty) {
        // Turning the lock off.
        final ok = await notifier.unlock(_current.text.trim());
        if (!ok) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.incorrectPin)));
          }
          return;
        }
        await notifier.disable();
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.appLockNowOff)));
          Navigator.of(context).pop();
        }
      } else {
        // Changing the PIN.
        final ok = await notifier.unlock(_current.text.trim());
        if (!ok) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.incorrectPin)));
          }
          return;
        }
        await notifier.setPin(_newPin.text.trim());
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.appLockNowOn)));
          Navigator.of(context).pop();
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _pinValidator(String? value) {
    final l10n = AppLocalizations.of(context);
    final text = value?.trim() ?? '';
    if (text.length < 4 || text.length > 6) return l10n.pinMustBe4To6Digits;
    if (!RegExp(r'^\d+$').hasMatch(text)) return l10n.pinMustBe4To6Digits;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final enabled = _isEnabled;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appLock)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(l10n.appLockDescription,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            if (enabled)
              TextFormField(
                controller: _current,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(labelText: l10n.currentPin),
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? l10n.enterPin : null,
              ),
            TextFormField(
              controller: _newPin,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(labelText: l10n.newPin),
              // Optional when turning the lock off; required otherwise.
              validator: enabled
                  ? (v) {
                      final text = v?.trim() ?? '';
                      if (text.isEmpty) return null;
                      return _pinValidator(text);
                    }
                  : _pinValidator,
            ),
            if (enabled)
              TextFormField(
                controller: _confirm,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(labelText: l10n.confirmPin),
                validator: (v) {
                  final text = v?.trim() ?? '';
                  if (_newPin.text.trim().isEmpty) return null;
                  if (text != _newPin.text.trim()) return l10n.pinsDoNotMatch;
                  return null;
                },
              ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _busy ? null : _submit,
              icon: Icon(
                  enabled ? Icons.lock_outline : Icons.lock_open),
              label: Text(enabled ? l10n.changePin : l10n.setPin),
            ),
            if (enabled) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: _busy
                    ? null
                    : () async {
                        // Clear both new-PIN fields so the form means "off".
                        _newPin.clear();
                        _confirm.clear();
                        await _submit();
                      },
                child: Text(l10n.turnOffAppLock),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
