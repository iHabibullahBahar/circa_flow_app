import 'package:circa_flow_main/src/imports/core_imports.dart';
import 'package:circa_flow_main/src/config/api_endpoints.dart';
import 'package:circa_flow_main/src/services/api_service.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final ApiService _api = ApiService.instance;

  FutureEither<List<NotificationModel>> getNotifications({int page = 1}) async {
    final result = await _api.post<Map<String, dynamic>>(
      zNotificationsEndpoint,
      data: {'page': page},
    );

    return result.map((response) {
      final List<dynamic> data = response['data']['data'] as List<dynamic>;
      return data.map((json) => NotificationModel.fromJson(json as Map<String, dynamic>)).toList();
    });
  }

  FutureEither<int> getUnreadCount() async {
    final result = await _api.post<Map<String, dynamic>>(zNotificationsUnreadCountEndpoint);

    return result.map((response) {
      return (response['data']['unread_count'] as num).toInt();
    });
  }

  FutureEither<void> markAsRead(String id) async {
    return _api.post<void>(zNotificationsReadEndpoint, data: {'id': id});
  }

  FutureEither<void> markAllAsRead() async {
    return _api.post<void>(zNotificationsReadAllEndpoint);
  }

  FutureEither<void> deleteNotification(String id) async {
    return _api.post<void>(zNotificationsDeleteEndpoint, data: {'id': id});
  }
}
