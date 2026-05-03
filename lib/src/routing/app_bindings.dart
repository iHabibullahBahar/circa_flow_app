import 'package:get/get.dart';
import 'package:circa_flow_main/src/config/config_controller.dart';
import 'package:circa_flow_main/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:circa_flow_main/src/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:circa_flow_main/src/features/auth/presentation/providers/auth_controller.dart';
import 'package:circa_flow_main/src/features/auth/presentation/providers/session_controller.dart';
import 'package:circa_flow_main/src/features/posts/presentation/providers/posts_controller.dart';
import 'package:circa_flow_main/src/features/events/presentation/providers/events_controller.dart';
import 'package:circa_flow_main/src/features/documents/presentation/providers/documents_controller.dart';
import 'package:circa_flow_main/src/services/deep_link_service.dart';
import 'package:circa_flow_main/src/features/messaging/presentation/providers/socket_manager.dart';

/// AppBindings is passed to GetMaterialApp as a fallback safety net.
/// In normal operation, controllers are already registered in main() before
/// runApp() is called, so this is effectively a no-op (GetX will skip
/// re-registration for controllers already put with permanent: true).
class AppBindings implements Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ConfigController>()) {
      Get.put<ConfigController>(ConfigController(), permanent: true);
    }

    if (!Get.isRegistered<AuthRepository>()) {
      Get.lazyPut<AuthRepository>(() => AuthRepositoryImpl(), fenix: true);
    }

    if (!Get.isRegistered<SessionController>()) {
      Get.put<SessionController>(
        SessionController(repository: Get.find<AuthRepository>()),
        permanent: true,
      );
    }

    if (!Get.isRegistered<AuthController>()) {
      Get.lazyPut<AuthController>(
        () => AuthController(repository: Get.find<AuthRepository>()),
        fenix: true,
      );
    }

    // Module controllers
    Get.lazyPut(() => PostsController(), fenix: true);
    Get.lazyPut(() => EventsController(), fenix: true);
    Get.lazyPut(() => DocumentsController(), fenix: true);

    // Deep linking — permanent singleton, initialized after session resolves
    if (!Get.isRegistered<DeepLinkService>()) {
      Get.put<DeepLinkService>(DeepLinkService(), permanent: true);
    }

    // WebSocket manager — permanent singleton, connect/disconnect driven by SessionController
    if (!Get.isRegistered<SocketManager>()) {
      Get.put<SocketManager>(SocketManager(), permanent: true);
    }
  }
}
