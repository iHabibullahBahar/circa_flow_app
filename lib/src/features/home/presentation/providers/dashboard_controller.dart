import 'package:circa_flow_main/src/imports/imports.dart';
import 'package:circa_flow_main/src/features/posts/presentation/providers/posts_controller.dart';
import 'package:circa_flow_main/src/features/events/presentation/providers/events_controller.dart';
import 'package:circa_flow_main/src/features/posts/data/models/post_model.dart';
import 'package:circa_flow_main/src/features/events/data/models/event_model.dart';

class DashboardController extends GetxController {
  final postsCtrl = Get.find<PostsController>();
  final eventsCtrl = Get.find<EventsController>();

  final RxList<PostModel> featuredPosts = <PostModel>[].obs;
  final RxList<EventModel> upcomingEvents = <EventModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      refreshData();
    });
  }

  Future<void> refreshData() async {
    isLoading.value = true;
    try {
      await Future.wait([
        Get.find<ConfigController>().loadConfig(),
        postsCtrl.refreshData(),
        eventsCtrl.refreshData(),
      ]);
      
      featuredPosts.value = postsCtrl.posts.take(3).toList();
      upcomingEvents.value = eventsCtrl.events.take(5).toList();
    } catch (e) {
      debugPrint('Dashboard refresh error: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
