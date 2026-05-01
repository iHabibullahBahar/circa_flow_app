import 'package:circa_flow_main/src/imports/imports.dart';
import 'package:circa_flow_main/src/features/posts/presentation/providers/posts_controller.dart';
import 'package:circa_flow_main/src/features/events/presentation/providers/events_controller.dart';
import 'package:circa_flow_main/src/features/posts/data/models/post_model.dart';
import 'package:circa_flow_main/src/features/events/data/models/event_model.dart';
import 'package:circa_flow_main/src/services/dashboard_service.dart';
import '../../data/models/dashboard_response_model.dart';

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
      final result = await DashboardService.instance.fetchDashboard();
      
      result.fold(
        (failure) {
          debugPrint('Dashboard refresh error: ${failure.message}');
          // On failure, we might want to fallback to separate calls or show error
        },
        (response) {
          // 1. Update Global Config (Banners, Branding, Modules)
          final configCtrl = Get.find<ConfigController>();
          configCtrl.config.value = response.config;
          configCtrl.status.value = ConfigStatus.ready;

          // 2. Update Dashboard Content
          featuredPosts.assignAll(response.posts);
          upcomingEvents.assignAll(response.events);
          
          AppLogger.info('✅ Dashboard data aggregated successfully');
        },
      );
    } catch (e) {
      debugPrint('Dashboard controller error: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
