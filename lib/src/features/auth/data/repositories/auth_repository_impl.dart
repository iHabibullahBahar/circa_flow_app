import 'package:circa_flow_main/src/imports/core_imports.dart';
import 'package:circa_flow_main/src/imports/packages_imports.dart';

import 'package:circa_flow_main/src/features/auth/domain/entities/user.dart';
import 'package:circa_flow_main/src/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthService _authService = AuthService.instance;

  @override
  Stream<AppUser?> get onAuthStateChanged {
    return _authService.authStateChanges.map((payload) {
      if (payload == null) return null;

      // Extract the member from the payload. Login/Register send {token, member}
      final memberData = (payload['member'] as Map<String, dynamic>?) ??
          (payload['data']?['member'] as Map<String, dynamic>?) ??
          payload;

      return _memberFromPayload(memberData);
    });
  }

  @override
  FutureEither<AppUser> login({
    required String identifier,
    required String password,
  }) async {
    final result =
        await _authService.login(identifier: identifier, password: password);

    return result.flatMap((payload) {
      if (payload == null) {
        return left(const ServerFailure('Login failed: empty response'));
      }
      // Backend ApiResponse::success wraps in { data: { token, member } }
      // AuthService.login() already unwraps 'data', so payload = { token, member }
      final memberData = (payload['member'] as Map<String, dynamic>?) ??
          (payload['data']?['member'] as Map<String, dynamic>?);

      if (memberData == null) {
        return left(const ServerFailure('Login failed: member data missing'));
      }
      return right(_memberFromPayload(memberData));
    });
  }

  @override
  FutureEither<void> logout() {
    return _authService.logout();
  }

  @override
  FutureEither<AppUser?> checkAuthState() async {
    // Fast path — no point hitting the network if no token is stored.
    final tokenResult =
        await SecureStorageService.instance.read('auth_token');
    bool hasToken = false;
    tokenResult.fold((_) {}, (t) => hasToken = t != null);

    if (!hasToken) return right(null);

    final result = await _authService.getCurrentUser();

    return result.map((data) {
      if (data == null) return null;
      // POST /me → ApiResponse::success(MemberResource) →
      // { data: { id, name, email, phone, is_active, ... } }
      final memberData = (data['data'] as Map<String, dynamic>?) ?? data;
      return _memberFromPayload(memberData);
    });
  }

  @override
  FutureEither<AppUser> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final result = await _authService.register(
      name: name,
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );

    return result.flatMap((payload) {
      if (payload == null) {
        return left(const ServerFailure('Registration failed'));
      }
      final memberData = (payload['member'] as Map<String, dynamic>?) ??
          (payload['data']?['member'] as Map<String, dynamic>?);

      if (memberData == null) {
        return left(const ServerFailure('Member data missing after registration'));
      }
      return right(_memberFromPayload(memberData));
    });
  }

  @override
  FutureEither<String> sendPasswordResetLink({required String email}) {
    return _authService.sendPasswordResetLink(email: email);
  }

  /// Maps a member JSON map (from MemberResource) to an [AppUser].
  AppUser _memberFromPayload(Map<String, dynamic> m) {
    return AppUser(
      id: m['id']?.toString() ?? '',
      email: (m['email'] as String?) ?? '',
      name: m['name'] as String?,
      phone: m['phone'] as String?,
      organizationId: m['organization_id'] as int?,
      isActive: (m['is_active'] as bool?) ?? true,
    );
  }
}
