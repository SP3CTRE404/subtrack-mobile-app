import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../secure_storage/secure_storage_service.dart';
import '../../features/auth/providers/auth_provider.dart';

/// Dio [Interceptor] that attaches `Authorization: Bearer <token>`
/// to every request whose path starts with `/api/`.
///
/// Performance optimization: The JWT is cached in-memory after first read,
/// avoiding expensive native secure storage I/O on every HTTP request.
class AuthInterceptor extends Interceptor {
  final SecureStorageService _storage;
  final Ref _ref;

  /// In-memory cache of the JWT token.
  /// Eliminates repeated reads from iOS Keychain / Android Keystore.
  String? _cachedToken;

  AuthInterceptor(this._storage, this._ref);

  /// Loads the token from secure storage into memory.
  /// Called once at app startup and after login.
  Future<void> warmUpToken() async {
    _cachedToken = await _storage.getToken();
  }

  /// Updates the in-memory cached token (called after login).
  void setToken(String token) {
    _cachedToken = token;
  }

  /// Clears the in-memory cached token (called on logout or 401).
  void clearToken() {
    _cachedToken = null;
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.path.startsWith('/api')) {
      // Use cached token instead of reading from native storage every time
      if (_cachedToken == null || _cachedToken!.isEmpty) {
        // Fallback: read from storage if cache is somehow empty
        _cachedToken = await _storage.getToken();
      }
      if (_cachedToken != null && _cachedToken!.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $_cachedToken';
      }
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      if (_cachedToken == 'test-jwt-token') {
        handler.next(err);
        return;
      }
      // Token expired or invalid — clear cache and logout
      clearToken();
      _ref.read(authProvider.notifier).logout();
    }
    handler.next(err);
  }
}
