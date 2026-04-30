import 'package:get/get.dart';
import 'package:circa_flow_main/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:circa_flow_main/src/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:circa_flow_main/src/features/auth/presentation/providers/auth_controller.dart';
import 'package:circa_flow_main/src/features/auth/presentation/providers/session_controller.dart';

class AppBindings implements Bindings {
  @override
  void dependencies() {
    // Repositories
    Get.lazyPut<AuthRepository>(() => AuthRepositoryImpl(), fenix: true);

    // Controllers
    Get.put<SessionController>(
      SessionController(repository: Get.find<AuthRepository>()),
      permanent: true,
    );

    Get.lazyPut<AuthController>(
      () => AuthController(repository: Get.find<AuthRepository>()),
      fenix: true,
    );
  }
}
