import 'dart:async';
import '../utils/utils.dart';
import '../config/api_endpoints.dart';
import 'secure_storage_service.dart';
import 'api_service.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final ApiService _api = ApiService.instance;

  /// Broadcast stream for auth state changes. Emits user map on login, null on logout.
  final StreamController<Map<String, dynamic>?> _authStateController =
      StreamController<Map<String, dynamic>?>.broadcast();

  Stream<Map<String, dynamic>?> get authStateChanges =>
      _authStateController.stream;

  /// Login using email/phone (identifier) and password.
  /// Backend expects: { identifier, password, device_name? }
  FutureEither<Map<String, dynamic>?> login({
    required String identifier,
    required String password,
    String? deviceName,
  }) async {
    final result = await _api.post<Map<String, dynamic>>(zLoginEndpoint, data: {
      'identifier': identifier,
      'password': password,
      if (deviceName != null) 'device_name': deviceName,
    });

    return result.map((data) {
      // Backend wraps in { data: { token, member } }
      final payload = (data['data'] as Map<String, dynamic>?) ?? data;
      final token = payload['token'] as String?;
      if (token != null) {
        SecureStorageService.instance.write('auth_token', token);
      }
      _authStateController.add(payload);
      return payload;
    });
  }

  /// Logout — revokes the current Sanctum token on the server.
  FutureEither<void> logout() async {
    // Always clear local state even if server call fails
    final result = await _api.post<void>(zLogoutEndpoint);
    
    // We ignore the server error for local state cleanup
    await SecureStorageService.instance.delete('auth_token');
    _authStateController.add(null);
    
    return result;
  }

  /// Returns the current member from the server using the stored token.
  /// Backend route: POST /api/v1/me
  FutureEither<Map<String, dynamic>?> getCurrentUser() async {
    return _api.post<Map<String, dynamic>>(zMeEndpoint);
  }

  /// Register a new member.
  FutureEither<Map<String, dynamic>?> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? deviceName,
  }) async {
    final result = await _api.post<Map<String, dynamic>>(zRegisterEndpoint, data: {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
      if (deviceName != null) 'device_name': deviceName,
    });

    return result.map((data) {
      final payload = (data['data'] as Map<String, dynamic>?) ?? data;
      final token = payload['token'] as String?;
      if (token != null) {
        SecureStorageService.instance.write('auth_token', token);
      }
      _authStateController.add(payload);
      return payload;
    });
  }

  /// Send a password reset link to email.
  FutureEither<String> sendPasswordResetLink({required String email}) async {
    final result = await _api.post<Map<String, dynamic>>(
      zForgotPasswordEndpoint,
      data: {'email': email},
    );
    return result.map((data) => (data['message'] as String?) ?? 'Reset link sent');
  }

  void dispose() {
    _authStateController.close();
  }
}
