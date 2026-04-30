import 'dart:async';
import '../utils/utils.dart';
import '../config/app_config.dart';
import 'package:dio/dio.dart';
import 'secure_storage_service.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  Dio get _dio => AppConfig.dio;

  // Custom Backend doesn't have a built-in auth state stream, so we manage our own
  final StreamController<Map<String, dynamic>?> _authStateController =
      StreamController<Map<String, dynamic>?>.broadcast();

  /// Stream of auth state changes. Emits the current user map or null.
  Stream<Map<String, dynamic>?> get authStateChanges => _authStateController.stream;

  FutureEither<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    return runTask(() async {
      final response = await _dio.post<Map<String, dynamic>>('/auth/login', data: {
        'email': email,
        'password': password,
      });
      final data = response.data as Map<String, dynamic>;
      
      // Save token if present
      final token = data['token'] ?? data['access_token'];
      if (token != null) {
        await SecureStorageService.instance.write('auth_token', token.toString());
      }

      _authStateController.add(data);
      return data;
    }, requiresNetwork: true);
  }

  FutureEither<Map<String, dynamic>?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    return runTask(() async {
      final response = await _dio.post<Map<String, dynamic>>('/auth/signup', data: {
        'name': name,
        'email': email,
        'password': password,
      });
      final data = response.data as Map<String, dynamic>;

      // Save token if present
      final token = data['token'] ?? data['access_token'];
      if (token != null) {
        await SecureStorageService.instance.write('auth_token', token.toString());
      }

      _authStateController.add(data);
      return data;
    }, requiresNetwork: true);
  }

  FutureEither<void> forgotPassword({required String email}) async {
    return runTask(() async {
      await _dio.post<void>('/auth/forgot-password', data: {'email': email});
    }, requiresNetwork: true);
  }

  FutureEither<void> logout() async {
    return runTask(() async {
      await _dio.post<void>('/auth/logout');
      await SecureStorageService.instance.delete('auth_token');
      _authStateController.add(null);
    }, requiresNetwork: true);
  }

  FutureEither<Map<String, dynamic>?> getCurrentUser() async {
    return runTask(() async {
      final response = await _dio.get<Map<String, dynamic>>('/auth/me');
      return response.data as Map<String, dynamic>;
    });
  }

  void dispose() {
    _authStateController.close();
  }
}
