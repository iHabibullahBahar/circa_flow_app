import 'package:circa_flow_main/src/utils/utils.dart';
import 'package:circa_flow_main/src/features/auth/domain/entities/user.dart';

abstract class AuthRepository {
  /// Stream of auth state changes. Emits AppUser when authenticated, null when not.
  Stream<AppUser?> get onAuthStateChanged;

  /// Sign in with identifier (email or phone) and password.
  FutureEither<AppUser> login({
    required String identifier,
    required String password,
  });

  /// Sign out the current user — revokes the Sanctum token on the server.
  FutureEither<void> logout();

  /// Check if the user is currently authenticated by calling POST /me.
  FutureEither<AppUser?> checkAuthState();

  /// Register a new member in the organization.
  FutureEither<AppUser> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  });

  /// Send a password reset link to the user's email.
  FutureEither<String> sendPasswordResetLink({required String email});
}
