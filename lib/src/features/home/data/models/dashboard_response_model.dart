import '../../../../config/app_config_model.dart';
import '../../../posts/data/models/post_model.dart';
import '../../../events/data/models/event_model.dart';

class DashboardResponse {
  final AppConfigModel config;
  final List<PostModel> posts;
  final List<EventModel> events;

  DashboardResponse({
    required this.config,
    required this.posts,
    required this.events,
  });

  factory DashboardResponse.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>?) ?? json;

    return DashboardResponse(
      config: AppConfigModel.fromJson(data),
      posts: (data['posts'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map((e) => PostModel.fromJson(e))
              .toList() ??
          [],
      events: (data['events'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map((e) => EventModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}
