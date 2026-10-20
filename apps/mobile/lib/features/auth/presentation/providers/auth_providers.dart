import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user_entity.dart';

/// Auth state: unauthenticated, loading, authenticated, error.
sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final UserEntity user;
  const AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

/// Auth state notifier.
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthInitial()) {
    _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    final hasTokens = await _repository.hasTokens();
    if (hasTokens) {
      try {
        final user = await _repository.getProfile();
        state = AuthAuthenticated(user);
      } catch (_) {
        await _repository.clearTokens();
        state = const AuthUnauthenticated();
      }
    } else {
      state = const AuthUnauthenticated();
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AuthLoading();
    try {
      final result = await _repository.login(email: email, password: password);
      state = AuthAuthenticated(result.user);
    } catch (e) {
      state = AuthError(_parseError(e));
    }
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    state = const AuthLoading();
    try {
      final result = await _repository.register(
        fullName: fullName,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
      );
      state = AuthAuthenticated(result.user);
    } catch (e) {
      state = AuthError(_parseError(e));
    }
  }

  Future<void> logout() async {
    state = const AuthLoading();
    try {
      await _repository.logout(null);
    } catch (_) {
      // Even if logout fails on server, clear local tokens
    } finally {
      state = const AuthUnauthenticated();
    }
  }

  /// Stable error codes, never display copy: a provider has no
  /// BuildContext, so it cannot see the active locale. The pages translate
  /// these through [authErrorMessage].
  String _parseError(dynamic e) {
    if (e.toString().contains('401')) {
      return 'auth.invalidCredentials';
    }
    if (e.toString().contains('400')) {
      return 'auth.invalidInput';
    }
    return 'auth.unknown';
  }
}

/// Maps an [AuthNotifier] error code to localized copy. An unknown code falls
/// back to the generic message so a new server error never shows a raw code.
String authErrorMessage(String code, AppLocalizations l10n) => switch (code) {
      'auth.invalidCredentials' => l10n.invalidEmailOrPassword,
      'auth.invalidInput' => l10n.checkYourInput,
      _ => l10n.somethingWentWrong,
    };

/// Auth state provider.
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});
