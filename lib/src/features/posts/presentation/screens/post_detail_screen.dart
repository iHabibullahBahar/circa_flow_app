import '../../../../imports/imports.dart';
import '../../data/models/post_model.dart';

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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'ANNOUNCEMENT',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w800,
                            color: cs.primary,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        post.formattedDate,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.black38,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
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
    Get.toNamed<void>(
      AppRoutes.webview,
      arguments: WebViewArgs(url: link.url, title: link.label),
    );
  }
}
