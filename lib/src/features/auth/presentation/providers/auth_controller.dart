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
      (failure) {
        showToast(context, message: failure.message, status: 'error');
      },
      (_) {
        Get.offAllNamed<void>(AppRoutes.home);
      },
    );
  }
}
