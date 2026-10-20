import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/app_config.dart';

/// Secure storage for auth tokens (encrypted on device).
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

/// Auth token data stored securely.
class AuthTokens {
  final String accessToken;
  final String refreshToken;

  AuthTokens({required this.accessToken, required this.refreshToken});
}

/// Provider for auth tokens (read from secure storage).
final authTokensProvider = FutureProvider<AuthTokens?>((ref) async {
  final storage = ref.read(secureStorageProvider);
  final access = await storage.read(key: 'access_token');
  final refresh = await storage.read(key: 'refresh_token');

  if (access == null || refresh == null) return null;
  return AuthTokens(accessToken: access, refreshToken: refresh);
});

/// Dio HTTP client with auth interceptors.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBase,
    connectTimeout: AppConfig.connectTimeout,
    receiveTimeout: AppConfig.receiveTimeout,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  dio.interceptors.add(AuthInterceptor(ref));

  return dio;
});

/// Interceptor that adds JWT token to requests and handles refresh on 401.
///
/// On a 401 it attempts a single refresh via /auth/refresh, stores the rotated
/// tokens, and retries the original request. If refresh fails, the error is
/// forwarded (the auth layer clears tokens and redirects to login).
class AuthInterceptor extends Interceptor {
  final Ref _ref;

  /// Marks a request that was already retried after a token refresh,
  /// preventing infinite refresh loops.
  static const _retriedFlag = 'auth_retry';

  /// The refresh currently in flight, shared by every request that 401s at the
  /// same moment.
  ///
  /// Without this, two parallel requests each rotate the refresh token; the
  /// second one presents a token the server has already seen, which is
  /// indistinguishable from a stolen copy — and the server now revokes the
  /// whole family in that case, signing the user out mid-session.
  Future<(String, String)?>? _refreshing;

  AuthInterceptor(this._ref);

  Future<(String, String)?> _refreshOnce() =>
      _refreshing ??= _refreshTokens().whenComplete(() => _refreshing = null);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final storage = _ref.read(secureStorageProvider);
    final token = await storage.read(key: 'access_token');
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401 ||
        err.requestOptions.extra[_retriedFlag] == true) {
      handler.next(err);
      return;
    }

    try {
      final refreshed = await _refreshOnce();
      if (refreshed == null) {
        handler.next(err);
        return;
      }

      final (accessToken, _) = refreshed;

      // Retry the original request with the new token.
      final options = err.requestOptions;
      options.headers['Authorization'] = 'Bearer $accessToken';
      options.extra[_retriedFlag] = true;

      // A bare Dio (no interceptors) performs the retry to avoid recursion.
      final retryDio = Dio(BaseOptions(
        baseUrl: AppConfig.apiBase,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ));
      final response = await retryDio.fetch(options);
      handler.resolve(response);
    } catch (_) {
      handler.next(err);
    }
  }

  /// Calls /auth/refresh and persists the rotated token pair.
  /// Returns the new (access, refresh) tokens, or null if refresh failed.
  Future<(String, String)?> _refreshTokens() async {
    final storage = _ref.read(secureStorageProvider);
    final refreshToken = await storage.read(key: 'refresh_token');
    if (refreshToken == null || refreshToken.isEmpty) return null;

    final dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBase,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    final response = await dio.post('/auth/refresh', data: {
      'refreshToken': refreshToken,
    });

    final data = response.data as Map<String, dynamic>;
    final accessToken = data['accessToken'] as String;
    final newRefreshToken = data['refreshToken'] as String;

    await storage.write(key: 'access_token', value: accessToken);
    await storage.write(key: 'refresh_token', value: newRefreshToken);

    return (accessToken, newRefreshToken);
  }
}
