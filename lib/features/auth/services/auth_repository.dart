import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/secure_storage/secure_storage_service.dart';
import '../../account/models/user_model.dart';
import '../models/auth_request.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final storage = ref.watch(secureStorageServiceProvider);
  return AuthRepository(dio: apiClient.dio, storage: storage, apiClient: apiClient);
});

class AuthRepository {
  final Dio dio;
  final SecureStorageService storage;
  final ApiClient apiClient;

  AuthRepository({required this.dio, required this.storage, required this.apiClient});

  String _extractErrorMessage(DioException e, String defaultMsg) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return e.message ?? defaultMsg;
  }

  // ── Hardcoded test credentials (bypass server) ──
  static const _testEmail = 'admin@mail.com';
  static const _testPassword = 'password';

  /// POST /auth/login → stores JWT + user info in secure storage.
  Future<void> login(LoginRequest request) async {
    // ── Offline test shortcut ──
    if (request.email == _testEmail && request.password == _testPassword) {
      await storage.saveToken('test-jwt-token');
      // Sync in-memory token cache
      apiClient.authInterceptor.setToken('test-jwt-token');
      await storage.saveUserId(1);
      await storage.saveUserEmail(_testEmail);
      await storage.saveUserName('Admin');
      return;
    }

    try {
      final response = await dio.post(
        ApiEndpoints.login,
        data: request.toJson(),
      );

      final data = response.data as Map<String, dynamic>;
      final token = data['token'] as String;

      await storage.saveToken(token);
      // Sync in-memory token cache
      apiClient.authInterceptor.setToken(token);

      // If the backend returns user info alongside the token, persist it.
      if (data.containsKey('user')) {
        final user = User.fromJson(data['user'] as Map<String, dynamic>);
        await storage.saveUserId(user.id);
        await storage.saveUserEmail(user.email);
        await storage.saveUserName(user.fullName);
      }
    } on DioException catch (e) {
      throw AuthException(_extractErrorMessage(e, 'Login failed. Please check your credentials.'));
    }
  }

  /// POST /auth/register → registers the user.
  Future<void> register(RegisterRequest request) async {
    try {
      await dio.post(
        ApiEndpoints.register,
        data: request.toJson(),
      );
    } on DioException catch (e) {
      throw AuthException(_extractErrorMessage(e, 'Registration failed. Please try again.'));
    }
    // Auto-login after successful registration.
    await login(LoginRequest(email: request.email, password: request.password));
  }

  /// Clears all persisted credentials.
  Future<void> logout() async {
    apiClient.authInterceptor.clearToken();
    await storage.clearAll();
  }

  /// Checks whether a JWT token is currently stored.
  Future<bool> hasValidToken() async {
    final token = await storage.getToken();
    return token != null && token.isNotEmpty;
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}
