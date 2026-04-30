import 'package:circa_flow_main/src/imports/core_imports.dart';
import 'package:circa_flow_main/src/imports/packages_imports.dart';

import 'package:circa_flow_main/src/features/auth/domain/repositories/auth_repository.dart';

class AuthController extends GetxController {
  final AuthRepository _repository;

  AuthController({required AuthRepository repository}) : _repository = repository;

  final isLoading = false.obs;

  void login({required BuildContext context, required String email, required String password}) async {
    isLoading.value = true;
    
    final result = await _repository.login(email: email, password: password);
    
    isLoading.value = false;
    result.fold(
      (failure) {
        showToast(context, message: failure.message, status: 'error');
      },
      (user) {
        Get.offAllNamed<void>(AppRoutes.home);
      },
    );
  }

  void signUp({required BuildContext context, required String name, required String email, required String password}) async {
    isLoading.value = true;
    
    final result = await _repository.signUp(name: name, email: email, password: password);
    
    isLoading.value = false;
    result.fold(
      (failure) {
        showToast(context, message: failure.message, status: 'error');
      },
      (user) {
        Get.offAllNamed<void>(AppRoutes.home);
      },
    );
  }

  void forgotPassword({required BuildContext context, required String email}) async {
    isLoading.value = true;
    
    final result = await _repository.forgotPassword(email: email);
    
    isLoading.value = false;
    result.fold(
      (failure) {
        showToast(context, message: failure.message, status: 'error');
      },
      (success) {
        showToast(context, message: 'Password reset link sent successfully', status: 'success');
        Get.offNamed<void>(AppRoutes.login);
      },
    );
  }
}
