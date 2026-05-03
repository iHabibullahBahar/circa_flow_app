import 'package:circa_flow_main/src/imports/imports.dart';
import '../providers/comments_controller.dart';
import '../widgets/comment_item.dart';
import '../widgets/comment_input_bar.dart';

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
  final Rx<ReplyContext?> _replyingTo = Rx<ReplyContext?>(null);
  final FocusNode _inputFocusNode = FocusNode();

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
    _inputFocusNode.dispose();
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
              '${controller.totalComments.value == 1 ? 'Comment' : 'Comments'} (${controller.totalComments.value})',
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
                      controller: controller,
                      onReply: (parent, onReplySuccess) {
                        setState(() {
                          _replyingTo.value = ReplyContext(parent, onReplySuccess);
                        });
                        _inputFocusNode.requestFocus();
                      },
                    );
                  },
                ),
              );
            }),
          ),
          CommentInputBar(
            controller: controller,
            textController: textController,
            replyingTo: _replyingTo,
            focusNode: _inputFocusNode,
          ),
        ],
      ),
    );
  }

}
