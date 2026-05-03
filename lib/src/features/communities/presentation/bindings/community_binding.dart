import 'package:circa_flow_main/src/imports/core_imports.dart';
import 'package:get/get.dart';
import '../../data/repositories/community_repository.dart';
import '../controllers/community_controller.dart';

class CommunityBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CommunityRepository>(() => CommunityRepositoryImpl());
    Get.lazyPut<CommunityController>(
      () => CommunityController(Get.find<CommunityRepository>()),
    );
  }
}
