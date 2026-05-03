import 'package:circa_flow_main/src/imports/imports.dart';
import '../../data/models/comment_model.dart';
import '../providers/comments_controller.dart';
import '../widgets/comment_item.dart';

class PostCommentsScreen extends StatefulWidget {
  final int postId;
  final String postTitle;
  const PostCommentsScreen({super.key, required this.postId, required this.postTitle});

  @override
  State<PostCommentsScreen> createState() => _PostCommentsScreenState();
}

class _PostCommentsScreenState extends State<PostCommentsScreen> {
  final textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late CommentsController controller;

  @override
  void initState() {
    super.initState();
    // Use a unique tag for each post's comments to avoid state collision
    controller = Get.put(CommentsController(postId: widget.postId), tag: widget.postId.toString());
    
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        controller.loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(() => Text(
              'Comments (${controller.totalComments.value})',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18.sp),
            )),
            Text(
              widget.postTitle,
              style: TextStyle(color: Colors.black38, fontSize: 12.sp, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.comments.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.comments.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 64.sp, color: Colors.black12),
                      const Gap(16),
                      Text('No comments yet. Be the first!', 
                        style: TextStyle(color: Colors.black26, fontSize: 14.sp, fontWeight: FontWeight.w500)),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => controller.fetchComments(),
                child: ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: controller.comments.length + (controller.hasNextPage.value ? 1 : 0),
                  separatorBuilder: (_, __) => const Gap(24),
                  itemBuilder: (ctx, i) {
                    if (i == controller.comments.length) {
                      return const Center(child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ));
                    }
                    return CommentItem(
                      key: ValueKey(controller.comments[i].id),
                      comment: controller.comments[i],
                      onReply: (parent, onReplySuccess) => _showReplySheet(context, controller, parent, onReplySuccess),
                    );
                  },
                ),
              );
            }),
          ),
          _buildInputArea(context),
        ],
      ),
    );
  }

  Widget _buildInputArea(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + context.mediaQueryViewPadding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.contextTheme.colorScheme.primary.withValues(alpha: 0.1)),
              ),
              child: TextField(
                controller: textController,
                decoration: InputDecoration(
                  hintText: 'Add a comment...',
                  hintStyle: TextStyle(color: Colors.black26, fontSize: 14.sp),
                  border: InputBorder.none,
                ),
                maxLines: null,
              ),
            ),
          ),
          const Gap(12),
          Obx(() => IconButton(
            onPressed: controller.isPosting.value ? null : () async {
              final success = await controller.postComment(textController.text);
              if (success) {
                textController.clear();
                FocusScope.of(context).unfocus();
              }
            },
            icon: Icon(
              Icons.send_rounded, 
              color: controller.isPosting.value ? Colors.black12 : context.contextTheme.colorScheme.primary,
            ),
          )),
        ],
      ),
    );
  }

  void _showReplySheet(BuildContext context, CommentsController controller, CommentModel parent, void Function(CommentModel) onReplySuccess) {
    final replyTextController = TextEditingController();
    Get.bottomSheet<void>(
      Container(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + context.mediaQueryViewPadding.bottom),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reply to ${parent.author?.firstName ?? 'Comment'}',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.sp),
            ),
            const Gap(16),
            TextField(
              controller: replyTextController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Write a reply...',
                filled: true,
                fillColor: const Color(0xFFF5F7F9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
              maxLines: 3,
            ),
            const Gap(16),
            SizedBox(
              width: double.infinity,
              child: Obx(() => AppButton(
                label: 'Post Reply',
                isLoading: controller.isPosting.value,
                onPressed: () async {
                  final reply = await controller.postReply(parent.id, replyTextController.text);
                  if (reply != null) {
                    Get.back<void>();
                    AppToast.success('Reply posted');
                    onReplySuccess(reply);
                  }
                },
              )),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}
