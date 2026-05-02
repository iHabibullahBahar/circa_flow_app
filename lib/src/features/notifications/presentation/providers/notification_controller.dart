import 'package:circa_flow_main/src/imports/core_imports.dart';
import 'package:circa_flow_main/src/imports/packages_imports.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';

class NotificationController extends GetxController {
  final NotificationRepository _repository = NotificationRepository();

  final notifications = <NotificationModel>[].obs;
  final isLoading = false.obs;
  final unreadCount = 0.obs;
  final currentPage = 1.obs;
  final hasMore = true.obs;

  @override
  void onInit() {
    super.onInit();
    refreshNotifications();
    fetchUnreadCount();
  }

  Future<void> fetchUnreadCount() async {
    final result = await _repository.getUnreadCount();
    result.fold(
      (failure) => null,
      (count) => unreadCount.value = count,
    );
  }

  Future<void> refreshNotifications() async {
    isLoading.value = true;
    currentPage.value = 1;
    hasMore.value = true;
    
    final result = await _repository.getNotifications(page: 1);
    
    result.fold(
      (failure) {
        isLoading.value = false;
        // Handle failure if needed
      },
      (list) {
        notifications.value = list;
        isLoading.value = false;
        if (list.length < 20) hasMore.value = false;
      },
    );
    
    fetchUnreadCount();
  }

  Future<void> loadMore() async {
    if (isLoading.value || !hasMore.value) return;

    currentPage.value++;
    final result = await _repository.getNotifications(page: currentPage.value);

    result.fold(
      (failure) {
        currentPage.value--;
      },
      (list) {
        if (list.isEmpty) {
          hasMore.value = false;
        } else {
          notifications.addAll(list);
          if (list.length < 20) hasMore.value = false;
        }
      },
    );
  }

  Future<void> markAsRead(NotificationModel notification) async {
    if (notification.isRead) return;

    final result = await _repository.markAsRead(notification.id);
    result.fold(
      (failure) => null,
      (_) {
        final index = notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          notifications[index] = NotificationModel(
            id: notification.id,
            title: notification.title,
            body: notification.body,
            deepLink: notification.deepLink,
            extra: notification.extra,
            createdAt: notification.createdAt,
            readAt: DateTime.now(),
          );
          fetchUnreadCount();
        }
      },
    );
  }

  Future<void> markAllAsRead() async {
    final result = await _repository.markAllAsRead();
    result.fold(
      (failure) => null,
      (_) {
        notifications.value = notifications.map((n) {
          return NotificationModel(
            id: n.id,
            title: n.title,
            body: n.body,
            deepLink: n.deepLink,
            extra: n.extra,
            createdAt: n.createdAt,
            readAt: n.readAt ?? DateTime.now(),
          );
        }).toList();
        unreadCount.value = 0;
      },
    );
  }

  Future<void> deleteNotification(String id) async {
    final result = await _repository.deleteNotification(id);
    result.fold(
      (failure) => null,
      (_) {
        notifications.removeWhere((n) => n.id == id);
        fetchUnreadCount();
      },
    );
  }
}
