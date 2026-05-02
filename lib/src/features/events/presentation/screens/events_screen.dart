import 'package:circa_flow_main/src/imports/imports.dart';
import '../providers/events_controller.dart';
import '../../data/models/event_model.dart';

class EventsScreen extends GetView<EventsController> {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = context.contextTheme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(5),
          child: Column(
            children: [
              Obx(() => Container(
                    decoration: BoxDecoration(
                      border: Border(
                          bottom: BorderSide(
                              color: cs.outlineVariant.withValues(alpha: 0.3))),
                    ),
                    child: Row(
                      children: [
                        _TabItem(
                          label: 'Upcoming',
                          isSelected:
                              controller.currentTab.value == EventTab.upcoming,
                          onTap: () => controller.setTab(EventTab.upcoming),
                        ),
                        _TabItem(
                          label: 'My Events',
                          isSelected:
                              controller.currentTab.value == EventTab.myEvents,
                          onTap: () => controller.setTab(EventTab.myEvents),
                        ),
                        _TabItem(
                          label: 'Past',
                          isSelected:
                              controller.currentTab.value == EventTab.past,
                          onTap: () => controller.setTab(EventTab.past),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
      body: Obx(() {
        if (controller.hasError.value) {
          return _ErrorView(onRetry: controller.refreshData);
        }

        if (controller.events.isEmpty && !controller.isLoading.value) {
          return const _EmptyView();
        }

        // --- Skeleton Loading State ---
        if (controller.events.isEmpty && controller.isLoading.value) {
          return AppShimmer(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (ctx, i) => _EventCard(
                event: EventModel(
                  id: 0,
                  title: 'Loading Event Name',
                  description:
                      'Description that might take two lines for loading state',
                  startsAt: '2026-01-01T00:00:00Z',
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refreshData,
          color: cs.primary,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollEndNotification &&
                  notification.metrics.extentAfter < 200) {
                controller.loadMore();
              }
              return false;
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: controller.events.length +
                  (controller.isLoading.value ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (ctx, i) {
                if (i >= controller.events.length) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: cs.primary),
                    ),
                  );
                }
                return _EventCard(event: controller.events[i]);
              },
            ),
          ),
        );
      }),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.contextTheme.colorScheme;
    final tt = context.contextTheme.textTheme;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(label,
                  style: tt.titleSmall?.copyWith(
                      color: isSelected ? cs.primary : cs.onSurfaceVariant)),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isSelected ? cs.primary : Colors.transparent,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(3)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Event Card ───────────────────────────────────────────────────────────────

class _EventCard extends StatelessWidget {
  final EventModel event;
  const _EventCard({required this.event});

  void _onTap() {
    Get.toNamed<void>(AppRoutes.eventDetail, arguments: event);
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.contextTheme.colorScheme;
    final tt = context.contextTheme.textTheme;

    return InkWell(
      onTap: _onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
          boxShadow: const [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Image Section with Tags & Date Badge ---
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: AppCachedImage(
                    imageUrl: event.coverImage ?? '',
                    height: 125.h,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),

                // --- Type Tag (Physical / Online / Hybrid) ---
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: event.type == 'online'
                          ? Colors.blue
                          : (event.type == 'hybrid'
                              ? Colors.orange
                              : Colors.green),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          event.type == 'online'
                              ? Icons.videocam_rounded
                              : (event.type == 'training'
                                  ? Icons.school_rounded
                                  : (event.type == 'hybrid'
                                      ? Icons.layers_rounded
                                      : Icons.location_on_rounded)),
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          event.type,
                          style: tt.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 10.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // --- Date Badge ---
                if (event.startsAt != null)
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getMonth(event.startsAt!).toUpperCase(),
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.red[500],
                            ),
                          ),
                          Text(
                            _getDay(event.startsAt!),
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // --- Content Section ---
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  Gap(8.h),

                  // --- Time Range ---
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          size: 14, color: cs.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Text(
                        _getTimeRange(event),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),

                  Gap(4.h),

                  // --- Location ---
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          size: 14, color: cs.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          event.isOnline ? 'Online' : (event.location ?? 'TBA'),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  // --- Spots left badge ---
                  if (event.registrationEnabled && event.spotsLeft != null) ...[
                    Gap(10.h),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: cs.outlineVariant.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.groups_rounded,
                              size: 14, color: cs.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Text(
                            '${event.spotsLeft} spots left',
                            style: TextStyle(
                                fontSize: 11.sp,
                                color: Colors.black87.withValues(alpha: 0.5)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeRange(EventModel event) {
    if (event.startsAt == null) return 'TBA';
    try {
      final start = DateTime.parse(event.startsAt!).toLocal();
      final startStr = _formatTime(start);
      if (event.endsAt != null) {
        final end = DateTime.parse(event.endsAt!).toLocal();
        return '$startStr - ${_formatTime(end)}';
      }
      return startStr;
    } catch (_) {
      return '';
    }
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${dt.minute.toString().padLeft(2, '0')} $period';
  }

  String _getDay(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return dt.day.toString();
    } catch (_) {
      return '';
    }
  }

  String _getMonth(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return months[dt.month - 1];
    } catch (_) {
      return '';
    }
  }
}

// ── Empty & Error states ─────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override
  Widget build(BuildContext context) {
    final cs = context.contextTheme.colorScheme;
    final tt = context.contextTheme.textTheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_outlined, size: 56, color: cs.outlineVariant),
          const SizedBox(height: 16),
          Text('No events yet',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});
  @override
  Widget build(BuildContext context) {
    final cs = context.contextTheme.colorScheme;
    final tt = context.contextTheme.textTheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded, size: 56, color: cs.error),
          const SizedBox(height: 16),
          Text('Could not load events',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 16),
          AppButton(
            label: 'Retry',
            onPressed: onRetry,
            variant: ButtonVariant.secondary,
          ),
        ],
      ),
    );
  }
}
