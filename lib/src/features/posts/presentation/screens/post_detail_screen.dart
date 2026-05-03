import '../../../../imports/imports.dart';
import '../../data/models/post_model.dart';
import '../providers/posts_controller.dart';
import '../providers/comments_controller.dart';
import '../widgets/comment_item.dart';
import '../widgets/comment_input_bar.dart';
import 'post_comments_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final PostModel post;
  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final Rx<ReplyContext?> _replyContext = Rx<ReplyContext?>(null);
  final FocusNode _inputFocusNode = FocusNode();
  int _previewLimit = 3;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commentsCtrl = Get.put(
      CommentsController(postId: widget.post.id), 
      tag: widget.post.id.toString(),
    );

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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Cover Image ---
                  if (widget.post.coverImage != null)
                    AppCachedImage(
                      imageUrl: widget.post.coverImage!,
                      width: double.infinity,
                      height: 220.h,
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
                          final currentPost = postCtrl.posts.firstWhere((p) => p.id == widget.post.id, orElse: () => widget.post);
                          
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
                                onTap: () => AppGuard.check(
                                  context,
                                  action: 'react_post',
                                  fallbackGuards: [GuardType.guest],
                                  onPass: () => postCtrl.toggleReaction(currentPost),
                                ),
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
                          widget.post.title,
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
                        if (widget.post.body != null)
                          Text(
                            widget.post.body!,
                            style: TextStyle(
                              fontSize: 15.sp,
                              color: Colors.black87.withValues(alpha: 0.7),
                              height: 1.6,
                            ),
                          ),

                        // --- Images Gallery ---
                        if (widget.post.images.isNotEmpty) ...[
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
                              itemCount: widget.post.images.length,
                              separatorBuilder: (_, __) => const Gap(12),
                              itemBuilder: (ctx, i) => ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: AppCachedImage(
                                  imageUrl: widget.post.images[i],
                                  width: 120.h,
                                  height: 120.h,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ],

                        // --- Links Section ---
                        if (widget.post.links.isNotEmpty) ...[
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
                          ...widget.post.links.map((link) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: InkWell(
                                  onTap: () => _handleLink(link),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5F7F9),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(Icons.link_rounded,
                                              color: Colors.blue, size: 20),
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

                        const Gap(32),
                        Obx(() {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '${commentsCtrl.totalComments.value == 1 ? 'Comment' : 'Comments'} (${commentsCtrl.totalComments.value})',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (commentsCtrl.totalComments.value > 3)
                                    TextButton(
                                      onPressed: () => Get.to<void>(() => PostCommentsScreen(postId: widget.post.id, postTitle: widget.post.title)),
                                      child: Text('View All', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
                                    ),
                                ],
                              ),
                              const Gap(12),
                              
                              if (commentsCtrl.isLoading.value && commentsCtrl.comments.isEmpty)
                                const Center(child: CircularProgressIndicator())
                              else if (commentsCtrl.comments.isEmpty)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 20),
                                    child: Text('No comments yet.', style: TextStyle(color: Colors.black26, fontSize: 12.sp)),
                                  ),
                                )
                              else
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  separatorBuilder: (_, __) => const Gap(24),
                                  itemBuilder: (ctx, i) => CommentItem(
                                    key: ValueKey(commentsCtrl.comments[i].id),
                                    comment: commentsCtrl.comments[i],
                                    controller: commentsCtrl,
                                    onReply: (parent, onReplySuccess) {
                                      setState(() {
                                        _replyContext.value = ReplyContext(parent, onReplySuccess);
                                      });
                                      _inputFocusNode.requestFocus();
                                    },
                                  ),
                                  itemCount: commentsCtrl.comments.length > _previewLimit ? _previewLimit : commentsCtrl.comments.length,
                                ),
                            ],
                          );
                        }),
                        const Gap(40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          CommentInputBar(
            controller: commentsCtrl,
            textController: _commentController,
            replyingTo: _replyContext,
            focusNode: _inputFocusNode,
            onCommentPosted: () {
              setState(() {
                _previewLimit++;
              });
            },
          ),
        ],
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
