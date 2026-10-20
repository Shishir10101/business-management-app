import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_lock_repository.dart';

/// App-lock state.
///
/// [isEnabled] reflects whether a PIN exists; [isLocked] is in-memory only —
/// it is deliberately not persisted, so killing the app always starts
/// unlocked and the lock engages on the lifecycle pause that precedes a
/// background switch.
class AppLockState {
  const AppLockState({
    this.isEnabled = false,
    this.isLocked = false,
    this.isLoading = true,
  });

  final bool isEnabled;
  final bool isLocked;
  final bool isLoading;

  AppLockState copyWith({
    bool? isEnabled,
    bool? isLocked,
    bool? isLoading,
  }) =>
      AppLockState(
        isEnabled: isEnabled ?? this.isEnabled,
        isLocked: isLocked ?? this.isLocked,
        isLoading: isLoading ?? this.isLoading,
      );
}

class AppLockNotifier extends StateNotifier<AppLockState> {
  AppLockNotifier(this._repo) : super(const AppLockState());

  final AppLockRepository _repo;

  /// Called once at startup so the UI knows whether a PIN exists.
  Future<void> load() async {
    final pin = await _repo.readPin();
    state = state.copyWith(isEnabled: pin != null, isLocked: false, isLoading: false);
  }

  /// Sets a new PIN (first time or a change). Validates length only — the
  /// confirmation happens in the UI before this is called.
  Future<void> setPin(String pin) async {
    await _repo.writePin(pin);
    state = state.copyWith(isEnabled: true, isLocked: false);
  }

  /// Removes the PIN and unlocks.
  Future<void> disable() async {
    await _repo.clearPin();
    state = state.copyWith(isEnabled: false, isLocked: false);
  }

  /// Engages the lock. No-op when app lock is not enabled.
  void lock() {
    if (state.isEnabled) state = state.copyWith(isLocked: true);
  }

  Future<bool> unlock(String pin) async {
    if (await _repo.verify(pin)) {
      state = state.copyWith(isLocked: false);
      return true;
    }
    return false;
  }
}

final appLockProvider =
    StateNotifierProvider<AppLockNotifier, AppLockState>((ref) {
  return AppLockNotifier(ref.watch(appLockRepositoryProvider));
});
