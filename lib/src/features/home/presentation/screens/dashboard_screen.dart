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
                        child: SizedBox(
                          height: 240.h,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: posts.length,
                            padding: const EdgeInsets.symmetric(horizontal: 0),
                            itemBuilder: (context, index) {
                              return _DashboardPostCard(post: posts[index]);
                            },
                          ),
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
                        child: SizedBox(
                          height: 175.h,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: events.length,
                            padding: const EdgeInsets.symmetric(horizontal: 0),
                            itemBuilder: (context, index) {
                              return _DashboardEventCard(event: events[index]);
                            },
                          ),
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

class _DashboardPostCard extends StatelessWidget {
  final PostModel post;
  const _DashboardPostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final cs = context.contextTheme.colorScheme;
    final tt = context.contextTheme.textTheme;

    return InkWell(
      onTap: () => Get.toNamed<void>(AppRoutes.postDetail, arguments: post),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16, bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // --- Full Bleed Background ---
              if (post.coverImage != null)
                AppCachedImage(
                  imageUrl: post.coverImage!,
                  fit: BoxFit.cover,
                )
              else
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [cs.primaryContainer, cs.surfaceContainerHighest],
                    ),
                  ),
                  child: Center(
                    child: Icon(Icons.article_rounded, 
                      size: 48, 
                      color: cs.onSurfaceVariant.withValues(alpha: 0.2)),
                  ),
                ),

              // --- Gradient Mask ---
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.8),
                    ],
                    stops: const [0.4, 0.6, 1.0],
                  ),
                ),
              ),

              // --- Content Overlay ---
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'NEWS',
                        style: TextStyle(
                          color: cs.onPrimary,
                          fontSize: 8.sp,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      post.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded, 
                          size: 12, color: Colors.white.withValues(alpha: 0.6)),
                        const SizedBox(width: 4),
                        Text(
                          post.formattedDate,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // --- Floating Reaction Bubble ---
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        post.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 14,
                        color: post.isLiked ? Colors.red : Colors.black54,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${post.reactionCount}',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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

class _DashboardEventCard extends StatelessWidget {
  final EventModel event;
  const _DashboardEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final cs = context.contextTheme.colorScheme;
    final tt = context.contextTheme.textTheme;

    return InkWell(
      onTap: () => Get.toNamed<void>(AppRoutes.eventDetail, arguments: event),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(right: 16, bottom: 4),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.appColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section with Date Overlay
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: AppCachedImage(
                      imageUrl: event.coverImage ?? '',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getDay(event.startsAt),
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w900,
                            color: cs.primary,
                            height: 1,
                          ),
                        ),
                        Text(
                          _getMon(event.startsAt).toUpperCase(),
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w900,
                            color: cs.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (event.registrationEnabled && event.spotsLeft != null)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${event.spotsLeft} spots left',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: tt.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 14.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 14, color: cs.primary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.location ?? 'TBA',
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontSize: 12.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded,
                          size: 14, color: cs.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        _getTime(event.startsAt),
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontSize: 12.sp,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        event.type.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w900,
                          color: cs.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
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
