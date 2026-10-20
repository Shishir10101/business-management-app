import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// PIN storage for the app lock.
///
/// The PIN lives in the platform keystore (Keychain / EncryptedSharedPrefs)
/// via [FlutterSecureStorage] — never in SharedPreferences, which is a plain
/// file on a rooted device. There is deliberately no "recover PIN" path:
/// forgetting it means reinstalling, which is the same tradeoff every
/// phone-lock makes and the only one that keeps a shopkeeper's khata safe.
class AppLockRepository {
  AppLockRepository({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _pinKey = 'khata.app_lock.pin';

  /// The stored PIN, or null when app lock has never been set up.
  Future<String?> readPin() async {
    try {
      final pin = await _storage.read(key: _pinKey);
      return (pin == null || pin.isEmpty) ? null : pin;
    } on Exception {
      // A keystore failure must not crash the app; treat it as "no PIN set"
      // so the app stays usable and the user can re-enable the lock.
      return null;
    }
  }

  Future<void> writePin(String pin) => _storage.write(key: _pinKey, value: pin);

  Future<void> clearPin() => _storage.delete(key: _pinKey);

  /// True when the stored value matches [pin]. Constant-time-ish: the
  /// comparison length is the PIN length either way.
  Future<bool> verify(String pin) async {
    final stored = await readPin();
    if (stored == null) return false;
    if (stored.length != pin.length) return false;
    var diff = 0;
    for (var i = 0; i < stored.length; i++) {
      diff |= stored.codeUnitAt(i) ^ pin.codeUnitAt(i);
    }
    return diff == 0;
  }
}

final appLockRepositoryProvider = Provider<AppLockRepository>(
  (ref) => AppLockRepository(),
);
