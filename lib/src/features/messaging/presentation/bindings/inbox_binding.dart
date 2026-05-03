import 'package:get/get.dart';
import 'package:circa_flow_main/src/features/messaging/presentation/providers/inbox_controller.dart';
import 'package:circa_flow_main/src/features/messaging/data/repositories/inbox_repository.dart';

class InboxBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<InboxRepository>(() => InboxRepository(), fenix: true);
    Get.put<InboxController>(
      InboxController(repository: Get.find<InboxRepository>()),
      tag: 'inbox_controller',
      permanent: false,
    );
  }
}
