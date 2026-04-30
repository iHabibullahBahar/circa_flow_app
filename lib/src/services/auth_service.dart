import 'dart:async';
import '../utils/utils.dart';
import '../config/api_endpoints.dart';
import 'secure_storage_service.dart';
import 'api_service.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final ApiService _api = ApiService.instance;

  // Custom Backend doesn't have a built-in auth state stream, so we manage our own
  final StreamController<Map<String, dynamic>?> _authStateController =
      StreamController<Map<String, dynamic>?>.broadcast();

  /// Stream of auth state changes. Emits the current user map or null.
  Stream<Map<String, dynamic>?> get authStateChanges => _authStateController.stream;

  FutureEither<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    final result = await _api.post<Map<String, dynamic>>(zLoginEndpoint, data: {
      'email': email,
      'password': password,
    });

    return result.map((data) {
      // Save token if present
      final token = data['token'] ?? data['access_token'];
      if (token != null) {
        SecureStorageService.instance.write('auth_token', token.toString());
      }

      _authStateController.add(data);
      return data;
    });
  }

  FutureEither<Map<String, dynamic>?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final result = await _api.post<Map<String, dynamic>>(zSignupEndpoint, data: {
      'name': name,
      'email': email,
      'password': password,
    });

    return result.map((data) {
      // Save token if present
      final token = data['token'] ?? data['access_token'];
      if (token != null) {
        SecureStorageService.instance.write('auth_token', token.toString());
      }

      _authStateController.add(data);
      return data;
    });
  }

  FutureEither<void> forgotPassword({required String email}) async {
    return _api.post<void>(zForgotPasswordEndpoint, data: {'email': email});
  }

  FutureEither<void> logout() async {
    final result = await _api.post<void>(zLogoutEndpoint);
    
    return result.map((_) {
      SecureStorageService.instance.delete('auth_token');
      _authStateController.add(null);
    });
  }

  FutureEither<Map<String, dynamic>?> getCurrentUser() async {
    return _api.get<Map<String, dynamic>>(zMeEndpoint);
  }

  void dispose() {
    _authStateController.close();
  }
}
