import 'package:circa_flow_main/src/imports/imports.dart';
import '../providers/posts_controller.dart';
import '../../data/models/post_model.dart';
import 'post_comments_screen.dart';

class PostsScreen extends GetView<PostsController> {
  const PostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = context.contextTheme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0, // No title needed
      ),
      body: Obx(() {
        if (controller.hasError.value) {
          return _ErrorView(onRetry: controller.refreshData);
        }

        return RefreshIndicator(
          onRefresh: controller.refreshData,
          color: cs.primary,
          child: CustomScrollView(
            slivers: [
              if (controller.posts.isEmpty && !controller.isLoading.value)
                const SliverFillRemaining(child: _EmptyView())
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index >= controller.posts.length) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: cs.primary),
                            ),
                          );
                        }
                        return _PostCard(post: controller.posts[index]);
                      },
                      childCount: controller.posts.length +
                          (controller.isLoading.value ? 1 : 0),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

// ── Post Card ────────────────────────────────────────────────────────────────

class _PostCard extends StatelessWidget {
  final PostModel post;
  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PostsController>();
    return InkWell(
      onTap: () => Get.toNamed<void>(AppRoutes.postDetail, arguments: post),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF0F0F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Media / Cover Image ---
            if (post.coverImage != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: AppCachedImage(
                  imageUrl: post.coverImage!,
                  height: 180.h,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Title ---
                  Text(
                    post.title,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF1A1A1A),
                      height: 1.3,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(10),

                  // --- Body Snippet ---
                  if (post.body != null)
                    Text(
                      post.body!,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.black54,
                        height: 1.5,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  
                  const Gap(20),
                  const Divider(height: 1, color: Color(0xFFF5F5F5)),
                  const Gap(16),

                  // --- Actions Bar ---
                  Row(
                    children: [
                      _ActionItem(
                        icon: post.isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                        label: '${post.reactionCount}',
                        isActive: post.isLiked,
                        activeColor: Colors.redAccent,
                        onTap: () => AppGuard.check(
                          context,
                          action: 'react_post',
                          fallbackGuards: [GuardType.guest],
                          onPass: () => controller.toggleReaction(post),
                        ),
                      ),
                      const Gap(20),
                      _ActionItem(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: '${post.commentsCount}',
                        onTap: () => Get.to<void>(() => PostCommentsScreen(postId: post.id, postTitle: post.title)),
                      ),
                      const Spacer(),
                      Text(
                        post.formattedDate,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.black26,
                          fontWeight: FontWeight.w700,
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
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color? activeColor;
  final VoidCallback? onTap;

  const _ActionItem({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.activeColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? (activeColor ?? Colors.blue) : Colors.black45;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const Gap(8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                color: color,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
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
          Icon(Icons.article_outlined, size: 56, color: cs.outlineVariant),
          const SizedBox(height: 16),
          Text('No posts yet',
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
          Text('Could not load posts',
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
