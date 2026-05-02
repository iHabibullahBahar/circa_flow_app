import '../../../../imports/imports.dart';
import '../../data/models/post_model.dart';
import '../providers/posts_controller.dart';

class PostDetailScreen extends StatelessWidget {
  final PostModel post;
  const PostDetailScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final cs = context.contextTheme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Get.back<void>(),
        ),
        title: Text(
          'Post Details',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Cover Image ---
            if (post.coverImage != null)
              AppCachedImage(
                imageUrl: post.coverImage!,
                width: double.infinity,
                height: 250.h,
                fit: BoxFit.cover,
              ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Header Row ---
                  Obx(() {
                    final postCtrl = Get.find<PostsController>();
                    // Find the post in the controller to ensure reactivity
                    final currentPost = postCtrl.posts.firstWhere((p) => p.id == post.id, orElse: () => post);
                    
                    return Row(
                      children: [
                        Text(
                          currentPost.formattedDate,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.black38,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () => postCtrl.toggleReaction(currentPost),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: currentPost.isLiked 
                                ? Colors.red.withValues(alpha: 0.1) 
                                : Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  currentPost.isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                                  color: currentPost.isLiked ? Colors.red : Colors.black45,
                                  size: 18,
                                ),
                                const Gap(8),
                                Text(
                                  '${currentPost.reactionCount}',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w800,
                                    color: currentPost.isLiked ? Colors.red : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  const Gap(20),

                  // --- Title ---
                  Text(
                    post.title,
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Gap(24),

                  // --- Body Content ---
                  if (post.body != null)
                    Text(
                      post.body!,
                      style: TextStyle(
                        fontSize: 15.sp,
                        color: Colors.black87.withValues(alpha: 0.7),
                        height: 1.6,
                      ),
                    ),

                  // --- Images Gallery ---
                  if (post.images.isNotEmpty) ...[
                    const Gap(32),
                    Text(
                      'Photos',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const Gap(16),
                    SizedBox(
                      height: 120.h,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: post.images.length,
                        separatorBuilder: (_, __) => const Gap(12),
                        itemBuilder: (ctx, i) => ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: AppCachedImage(
                            imageUrl: post.images[i],
                            width: 120.h,
                            height: 120.h,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ],

                  // --- Links Section ---
                  if (post.links.isNotEmpty) ...[
                    const Gap(32),
                    Text(
                      'Links & Attachments',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const Gap(12),
                    ...post.links.map((link) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () => _handleLink(link),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: cs.surface,
                                borderRadius: BorderRadius.circular(16),
                                border:
                                    Border.all(color: context.appColors.border),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: cs.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(Icons.link_rounded,
                                        color: cs.primary, size: 20),
                                  ),
                                  const Gap(16),
                                  Expanded(
                                    child: Text(
                                      link.label,
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.open_in_new_rounded,
                                      size: 16, color: Colors.black26),
                                ],
                              ),
                            ),
                          ),
                        )),
                  ],
                  const Gap(40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLink(PostLink link) {
    if (link.target == 'browser') {
      launchUrl(Uri.parse(link.url), mode: LaunchMode.externalApplication);
    } else {
      Get.toNamed<void>(
        AppRoutes.webview,
        arguments: WebViewArgs(url: link.url, title: link.label),
      );
    }
  }
}
