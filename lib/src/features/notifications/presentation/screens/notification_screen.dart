import 'package:circa_flow_main/src/imports/imports.dart';
import '../providers/notification_controller.dart';
import '../../data/models/notification_model.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NotificationController());
    final cs = context.contextTheme.colorScheme;
    final tt = context.contextTheme.textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          Obx(() => controller.unreadCount.value > 0
              ? TextButton(
                  onPressed: controller.markAllAsRead,
                  child: Text(
                    'Mark Read',
                    style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold),
                  ),
                )
              : const SizedBox.shrink()),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.notifications.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none_rounded, size: 48, color: cs.outlineVariant),
                const SizedBox(height: 16),
                Text(
                  'No notifications yet',
                  style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refreshNotifications,
          child: ListView.builder(
            itemCount: controller.notifications.length + (controller.hasMore.value ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == controller.notifications.length) {
                controller.loadMore();
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final notification = controller.notifications[index];
              return _NotificationTile(notification: notification);
            },
          ),
        );
      }),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  const _NotificationTile({required this.notification});

  void _showNotificationDetail(BuildContext context, NotificationController controller) {
    final cs = context.contextTheme.colorScheme;
    final tt = context.contextTheme.textTheme;

    controller.markAsRead(notification);

    Get.bottomSheet<void>(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Details',
                  style: tt.labelLarge?.copyWith(color: cs.primary, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Get.back<void>(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              notification.title,
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              notification.body,
              style: tt.bodyMedium,
            ),
            if (notification.deepLink != null) ...[
              const SizedBox(height: 24),
              AppButton(
                label: 'View Details',
                onPressed: () {
                  Get.back<void>();
                  Get.toNamed<void>(notification.deepLink!);
                },
                isFullWidth: true,
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificationController>();
    final cs = context.contextTheme.colorScheme;
    final tt = context.contextTheme.textTheme;

    return InkWell(
      onTap: () => _showNotificationDetail(context, controller),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.transparent : cs.primary.withValues(alpha: 0.05),
          border: Border(
            bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              notification.isRead ? Icons.notifications_outlined : Icons.notifications_active,
              color: notification.isRead ? cs.onSurfaceVariant : cs.primary,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: tt.bodyLarge?.copyWith(
                            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        timeago.format(notification.createdAt),
                        style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
