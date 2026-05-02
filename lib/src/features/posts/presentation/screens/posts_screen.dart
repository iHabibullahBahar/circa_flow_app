import 'package:circa_flow_main/src/imports/imports.dart';
import '../providers/posts_controller.dart';
import '../../data/models/post_model.dart';

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
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(8),

                  // --- Snippet ---
                  if (post.body != null)
                    Text(
                      post.body!,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            // --- Media ---
            if (post.coverImage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AppCachedImage(
                    imageUrl: post.coverImage!,
                    height: 200.h,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            // --- Reactions Row & Date ---
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  _ReactionItem(
                    icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
                    count: post.reactionCount.toString(),
                    isActive: post.isLiked,
                    onTap: () => controller.toggleReaction(post),
                  ),
                  const Spacer(),
                  Text(
                    post.formattedDate,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.black26,
                      fontWeight: FontWeight.w600,
                    ),
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

class _ReactionItem extends StatelessWidget {
  final IconData icon;
  final String count;
  final bool isActive;
  final VoidCallback? onTap;

  const _ReactionItem({
    required this.icon,
    required this.count,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? Colors.redAccent : Colors.black26,
            ),
            const Gap(8),
            Text(
              count,
              style: TextStyle(
                fontSize: 13.sp,
                color: isActive ? Colors.redAccent : Colors.black45,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
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
