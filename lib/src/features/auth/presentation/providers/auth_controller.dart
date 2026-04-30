import 'package:circa_flow_main/src/imports/core_imports.dart';
import 'package:circa_flow_main/src/imports/packages_imports.dart';
import 'package:circa_flow_main/src/features/auth/domain/repositories/auth_repository.dart';

class AuthController extends GetxController {
  final AuthRepository _repository;

  AuthController({required AuthRepository repository})
      : _repository = repository;

  final isLoading = false.obs;

  /// Login with email or phone number as identifier.
  void login({
    required BuildContext context,
    required String identifier,
    required String password,
  }) async {
    isLoading.value = true;

    final result =
        await _repository.login(identifier: identifier, password: password);

    isLoading.value = false;
    result.fold(
      (failure) => showToast(context, message: failure.message, status: 'error'),
      (_) => Get.offAllNamed<void>(AppRoutes.home),
    );
  }

  /// Register a new member.
  void register({
    required BuildContext context,
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    isLoading.value = true;

    final result = await _repository.register(
      name: name,
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );

    isLoading.value = false;
    result.fold(
      (failure) => showToast(context, message: failure.message, status: 'error'),
      (_) {
        showToast(context, message: 'Account created successfully!', status: 'success');
        Get.offAllNamed<void>(AppRoutes.home);
      },
    );
  }

  /// Send a reset link for password recovery.
  void forgotPassword({
    required BuildContext context,
    required String email,
  }) async {
    isLoading.value = true;
    final result = await _repository.sendPasswordResetLink(email: email);
    isLoading.value = false;

    result.fold(
      (failure) => showToast(context, message: failure.message, status: 'error'),
      (message) {
        showToast(context, message: message, status: 'success');
        // We don't go to a reset screen in-app anymore.
        // User clicks the link in their email and resets on the website.
        Get.back<void>();
      },
    );
  }
}
