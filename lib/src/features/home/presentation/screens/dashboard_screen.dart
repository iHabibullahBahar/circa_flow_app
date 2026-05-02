import 'dart:ui';
import 'package:circa_flow_main/src/imports/imports.dart';
import 'package:circa_flow_main/src/config/config_controller.dart';
import 'package:circa_flow_main/src/features/home/presentation/providers/dashboard_controller.dart';
import 'package:circa_flow_main/src/features/home/presentation/providers/home_shell_controller.dart';
import 'package:circa_flow_main/src/features/posts/data/models/post_model.dart';
import 'package:circa_flow_main/src/features/events/data/models/event_model.dart';
import 'package:circa_flow_main/src/shared/widgets/app_cached_image.dart';

import 'package:circa_flow_main/src/features/notifications/presentation/providers/notification_controller.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final configCtrl = Get.find<ConfigController>();
    final dashCtrl = Get.put(DashboardController());
    final notificationCtrl = Get.put(NotificationController());
    final cs = context.contextTheme.colorScheme;
    final tt = context.contextTheme.textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Obx(() => AppShimmer(
            enabled: dashCtrl.isLoading.value,
            child: RefreshIndicator(
              onRefresh: () async {
                await dashCtrl.refreshData();
                await notificationCtrl.refreshNotifications();
              },
              child: CustomScrollView(
                slivers: [
                  // --- Premium Header ---
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          _buildLogo(configCtrl),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  configCtrl.orgName.toUpperCase(),
                                  style: tt.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                    fontSize: 16.sp,
                                    color: cs.primary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'OFFICIAL PLATFORM',
                                  style: tt.labelSmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                    letterSpacing: 2.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                Get.toNamed<void>(AppRoutes.notifications),
                            icon: Obx(() {
                              final count = notificationCtrl.unreadCount.value;
                              return Badge(
                                label: Text(count.toString()),
                                isLabelVisible: count > 0,
                                child: Icon(Icons.notifications_none_rounded,
                                    color: cs.onSurface),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // --- Banners Carousel ---
                  SliverToBoxAdapter(
                    child: Obx(() {
                      final banners = configCtrl.config.value.banners;
                      if (banners.isEmpty) return const SizedBox.shrink();
                      return _DashboardBanners(banners: banners);
                    }),
                  ),

                  // --- Latest Posts Section ---
                  SliverToBoxAdapter(
                    child: Obx(() {
                      final posts = dashCtrl.featuredPosts;
                      final isEnabled = configCtrl.config.value.modules.posts;
                      if (!isEnabled || posts.isEmpty)
                        return const SizedBox.shrink();

                      return _DashboardSection(
                        title: 'Latest Posts',
                        onViewAll: () => Get.find<HomeShellController>()
                            .changeTabByLabel('Posts'),
                        child: Column(
                          children: posts
                              .take(2)
                              .map((p) => _PostListTile(post: p))
                              .toList(),
                        ),
                      );
                    }),
                  ),

                  // --- Upcoming Events Section ---
                  SliverToBoxAdapter(
                    child: Obx(() {
                      final events = dashCtrl.upcomingEvents;
                      final isEnabled = configCtrl.config.value.modules.events;
                      if (!isEnabled || events.isEmpty)
                        return const SizedBox.shrink();

                      return _DashboardSection(
                        title: 'Upcoming Events',
                        onViewAll: () => Get.find<HomeShellController>()
                            .changeTabByLabel('Events'),
                        child: Column(
                          children: events
                              .take(2)
                              .map((e) => _EventListTile(event: e))
                              .toList(),
                        ),
                      );
                    }),
                  ),

                  // --- Resources / Quick Actions ---
                  SliverToBoxAdapter(
                    child: Obx(() {
                      final isEnabled =
                          configCtrl.config.value.modules.documents;
                      if (!isEnabled) return const SizedBox.shrink();

                      return _DashboardSection(
                        title: 'Resources',
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: context.appColors.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: context.appColors.placeholder,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.description_rounded,
                                    color: cs.onSurfaceVariant),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Member Handbook',
                                      style: tt.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'Tap to view or download',
                                      style: tt.bodySmall?.copyWith(
                                          color: cs.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded,
                                  color: cs.onSurfaceVariant),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
            ))),
      ),
    );
  }

  Widget _buildLogo(ConfigController configCtrl) {
    final cs = Get.context!.contextTheme.colorScheme;
    if (configCtrl.logoUrl != null) {
      return AppCachedImage(
        imageUrl: configCtrl.logoUrl!,
        height: 48,
        width: 48,
        fit: BoxFit.contain,
      );
    }
    return Container(
      height: 48,
      width: 48,
      decoration: BoxDecoration(
        color: Get.context!.appColors.placeholder,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.business_rounded, color: cs.onSurfaceVariant),
    );
  }
}

class _PostListTile extends StatelessWidget {
  final PostModel post;
  const _PostListTile({required this.post});

  @override
  Widget build(BuildContext context) {
    final cs = context.contextTheme.colorScheme;
    final tt = context.contextTheme.textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.border),
      ),
      child: Row(
        children: [
          if (post.coverImage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 80,
                height: 80,
                child: AppCachedImage(
                  imageUrl: post.coverImage!,
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Get.context!.appColors.placeholder,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.article_rounded, color: cs.onSurfaceVariant),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title,
                  style: tt.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  post.body ?? '',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 12, color: cs.primary),
                    const SizedBox(width: 4),
                    Text(
                      post.formattedDate,
                      style:
                          tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
        ],
      ),
    );
  }
}

class _DashboardSection extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAll;
  final Widget child;

  const _DashboardSection({
    required this.title,
    this.onViewAll,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final tt = context.contextTheme.textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 18.sp,
                ),
              ),
              if (onViewAll != null)
                AppButton(
                  label: 'View all',
                  onPressed: onViewAll,
                  variant: ButtonVariant.ghost,
                  height: ButtonSize.small,
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _EventListTile extends StatelessWidget {
  final EventModel event;
  const _EventListTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final cs = context.contextTheme.colorScheme;

    return InkWell(
      onTap: () => Get.toNamed<void>(AppRoutes.eventDetail, arguments: event),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.appColors.border),
        ),
        child: Row(
          children: [
            // Thumbnail with Date Overlay
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: AppCachedImage(
                      imageUrl: event.coverImage ?? '',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.05),
                        width: 0.5,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getDay(event.startsAt),
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w900,
                            color: cs.primary,
                            height: 1,
                          ),
                        ),
                        Text(
                          _getMon(event.startsAt).toUpperCase(),
                          style: TextStyle(
                            fontSize: 8.sp,
                            fontWeight: FontWeight.w900,
                            color: cs.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const Gap(16),
            // Info Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.type,
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(8),
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded,
                          size: 14, color: Colors.black38),
                      const Gap(4),
                      Text(
                        _getTime(event.startsAt),
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.black45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Gap(12),
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: Colors.black38),
                      const Gap(4),
                      Expanded(
                        child: Text(
                          event.location ?? 'TBA',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.black45,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // if (event.registrationEnabled &&
                      //     event.spotsLeft != null) ...[
                      //   Container(
                      //     padding: const EdgeInsets.symmetric(
                      //         horizontal: 6, vertical: 3),
                      //     decoration: BoxDecoration(
                      //       color: cs.primary.withValues(alpha: 0.1),
                      //       borderRadius: BorderRadius.circular(4),
                      //     ),
                      //     child: Text(
                      //       '${event.spotsLeft} left',
                      //       style: TextStyle(
                      //         fontSize: 10.sp,
                      //         fontWeight: FontWeight.w600,
                      //         color: cs.primary,
                      //         letterSpacing: 0.5,
                      //       ),
                      //     ),
                      //   ),
                      // ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTime(String? date) {
    if (date == null) return 'TBA';
    try {
      final dt = DateTime.parse(date).toLocal();
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '$hour:${dt.minute.toString().padLeft(2, '0')} $ampm';
    } catch (_) {
      return 'TBA';
    }
  }

  String _getDay(String? date) {
    if (date == null) return '';
    try {
      return DateTime.parse(date).day.toString();
    } catch (_) {
      return '';
    }
  }

  String _getMon(String? date) {
    if (date == null) return '';
    try {
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
      return months[DateTime.parse(date).month - 1];
    } catch (_) {
      return '';
    }
  }
}

class _DashboardBanners extends StatefulWidget {
  final List<BannerConfig> banners;
  const _DashboardBanners({required this.banners});

  @override
  State<_DashboardBanners> createState() => _DashboardBannersState();
}

class _DashboardBannersState extends State<_DashboardBanners> {
  late final PageController _controller;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.9);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 180.h,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.banners.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final banner = widget.banners[index];
              return AnimatedScale(
                scale: _currentPage == index ? 1.0 : 0.95,
                duration: const Duration(milliseconds: 300),
                child: GestureDetector(
                  onTap: () => _handleAction(banner),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          AppCachedImage(
                            imageUrl: banner.imageUrl,
                            fit: BoxFit.cover,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.banners.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: AnimatedSmoothIndicator(
              activeIndex: _currentPage,
              count: widget.banners.length,
              effect: ExpandingDotsEffect(
                dotHeight: 6,
                dotWidth: 6,
                activeDotColor: context.contextTheme.colorScheme.primary,
                dotColor: context.contextTheme.colorScheme.outlineVariant,
              ),
            ),
          ),
      ],
    );
  }

  void _handleAction(BannerConfig banner) {
    if (banner.actionType == 'none' || banner.actionValue == null) return;

    switch (banner.actionType) {
      case 'link':
        Get.toNamed('/webview', arguments: {
          'url': banner.actionValue,
          'title': banner.title ?? 'Link',
        });
        break;
      case 'event':
        Get.find<HomeShellController>().changeTabByLabel('Events');
        break;
      case 'document':
        Get.find<HomeShellController>().changeTabByLabel('Documents');
        break;
    }
  }
}
