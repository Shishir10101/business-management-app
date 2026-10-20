import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/data/repositories/auth_repository_impl.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../core/l10n/calendar_provider.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/utils/nepali_date_utils.dart';
import '../../../../l10n/app_localizations.dart';

/// User profile: view details, edit name/phone/locale, logout.
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  var _locale = 'ne';
  var _editing = false;
  var _saving = false;

  UserEntity? get _currentUser {
    final state = ref.read(authStateProvider);
    return state is AuthAuthenticated ? state.user : null;
  }

  @override
  void initState() {
    super.initState();
    final user = _currentUser;
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    // The switcher reflects what the app is actually showing, not a stale
    // server field — the two used to disagree (the dropdown read "नेपाली"
    // while every screen was in English).
    _locale = ref.read(localeProvider).languageCode;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await ref.read(authRepositoryProvider).updateProfile(
            fullName: _nameController.text.trim(),
            phoneNumber: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
            locale: _locale,
          );
      // Refresh the session so the header reflects the new values.
      final profile = await ref.read(authRepositoryProvider).getProfile();
      ref.read(authStateProvider.notifier).state = AuthAuthenticated(profile);

      if (!mounted) return;
      setState(() => _editing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.profileUpdated)),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.couldNotUpdateProfile('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Saves the language on the account without touching the rest of the
  /// profile. Fire-and-forget by design: the device already has the choice.
  Future<void> _pushLocaleToAccount(String code) async {
    final state = ref.read(authStateProvider);
    if (state is! AuthAuthenticated) return;
    try {
      await ref.read(authRepositoryProvider).updateProfile(
            fullName: state.user.fullName,
            phoneNumber: state.user.phoneNumber,
            locale: code,
          );
    } catch (_) {
      // Offline or refused: the device preference still stands.
    }
  }

  Future<void> _logout() async {
    await ref.read(authStateProvider.notifier).logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final state = ref.watch(authStateProvider);
    final user = state is AuthAuthenticated ? state.user : null;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profile)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                CircleAvatar(
                  radius: 40,
                  child: Text(
                    (user?.fullName ?? '?').substring(0, 1).toUpperCase(),
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.email ?? '',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _nameController,
                  enabled: _editing,
                  decoration: InputDecoration(
                    labelText: l10n.fullNamePlaceholder,
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.fullNameIsRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  enabled: _editing,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: l10n.phoneNumberPlaceholder,
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                SizedBox(height: 16),
                // Language and calendar apply the moment they are chosen —
                // they are reading preferences, not profile fields, so they
                // are not gated behind "Edit profile" (that gate was why the
                // language switcher appeared to do nothing).
                DropdownButtonFormField<String>(
                  value: _locale,
                  decoration: InputDecoration(
                    labelText: l10n.language,
                    prefixIcon: const Icon(Icons.language),
                  ),
                  items: [
                    DropdownMenuItem(
                        value: 'en', child: Text(l10n.languageEnglish)),
                    DropdownMenuItem(
                        value: 'ne', child: Text(l10n.languageNepali)),
                    DropdownMenuItem(
                        value: 'hi', child: Text(l10n.languageHindi)),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _locale = value);
                    ref.read(localeProvider.notifier).setLocale(Locale(value));
                    // Best effort: keep the account's locale in step so a new
                    // device starts in the language this user actually reads.
                    // A failure here must not disturb the switch — the choice
                    // is already applied and saved on the device.
                    _pushLocaleToAccount(value);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<CalendarSystem>(
                  value: ref.watch(calendarProvider),
                  decoration: InputDecoration(
                    labelText: l10n.calendarLabel,
                    prefixIcon: const Icon(Icons.event_note_outlined),
                    helperText: l10n.calendarNote,
                    helperMaxLines: 2,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: CalendarSystem.ad,
                      child: Text(l10n.calendarAd),
                    ),
                    DropdownMenuItem(
                      value: CalendarSystem.bs,
                      child: Text(l10n.calendarBs),
                    ),
                  ],
                  onChanged: (value) => ref
                      .read(calendarProvider.notifier)
                      .setCalendar(value ?? CalendarSystem.ad),
                ),
                const SizedBox(height: 24),
                if (_editing) ...[
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.saveChanges),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed:
                        _saving ? null : () => setState(() => _editing = false),
                    child: Text(l10n.cancel),
                  ),
                ] else
                  ElevatedButton(
                    onPressed: () => setState(() => _editing = true),
                    child: Text(l10n.editProfile),
                  ),
                const SizedBox(height: 32),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.swap_horiz),
                  title: Text(l10n.switchBusiness),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/businesses'),
                ),
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: Text(l10n.appLock),
                  subtitle: Text(l10n.appLockDescription),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/settings/app-lock'),
                ),
                ListTile(
                  leading: const Icon(Icons.calculate_outlined),
                  title: Text(l10n.toolsTitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/tools/calculators'),
                ),
                ListTile(
                  leading: const Icon(Icons.account_balance_outlined),
                  title: Text(l10n.bankAccounts),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/businesses/bank-accounts'),
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title:
                      Text(l10n.logout, style: TextStyle(color: Colors.red)),
                  onTap: _logout,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
