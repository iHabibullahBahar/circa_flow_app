import '../../../../imports/imports.dart';
import '../providers/comments_controller.dart';
import 'comment_item.dart';

class CommentInputBar extends StatelessWidget {
  final CommentsController controller;
  final TextEditingController textController;
  final Rx<ReplyContext?> replyingTo;
  final FocusNode? focusNode;
  final VoidCallback? onCommentPosted;

  const CommentInputBar({
    super.key,
    required this.controller,
    required this.textController,
    required this.replyingTo,
    this.focusNode,
    this.onCommentPosted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.contextTheme;
    final primaryColor = theme.colorScheme.primary;

    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + context.mediaQueryViewPadding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- Reply Banner ---
          Obx(() {
            if (replyingTo.value == null) return const SizedBox.shrink();
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Icon(Icons.reply_rounded, size: 14, color: primaryColor),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      'Replying to ${replyingTo.value!.parent.author?.firstName ?? 'Comment'} for ${replyingTo.value!.parent.content}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: primaryColor,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => replyingTo.value = null,
                    child: Icon(Icons.close_rounded,
                        size: 16, color: primaryColor.withValues(alpha: 0.4)),
                  ),
                ],
              ),
            );
          }),

          // --- Input Row ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: textController,
                    focusNode: focusNode,
                    autofocus: false,
                    readOnly: !AppGuard.canProceed(action: 'comment_post', fallbackGuards: [GuardType.guest]),
                    onTap: () {
                      AppGuard.check(
                        context,
                        action: 'comment_post',
                        fallbackGuards: [GuardType.guest],
                        onPass: () {},
                      );
                    },
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: TextStyle(
                        color: const Color(0xFF94A3B8),
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    maxLines: 5,
                    minLines: 1,
                  ),
                ),
              ),
              const Gap(12),
              Obx(() {
                final isPosting = controller.isPosting.value;
                return InkWell(
                  onTap: isPosting ? null : () => _submit(context),
                  borderRadius: BorderRadius.circular(50),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isPosting
                          ? Colors.black.withValues(alpha: 0.05)
                          : primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: isPosting
                          ? []
                          : [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: isPosting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.black26),
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  void _submit(BuildContext context) async {
    AppGuard.check(
      context,
      action: 'comment_post',
      fallbackGuards: [GuardType.guest],
      onPass: () async {
        final text = textController.text.trim();
        if (text.isEmpty) return;

        if (replyingTo.value != null) {
          final contextObj = replyingTo.value!;
          final reply = await controller.postReply(contextObj.parent.id, text);
          if (reply != null) {
            contextObj.onReplySuccess(reply);
            textController.clear();
            replyingTo.value = null;
            FocusScope.of(context).unfocus();
          }
        } else {
          final success = await controller.postComment(text);
          if (success) {
            textController.clear();
            FocusScope.of(context).unfocus();
            onCommentPosted?.call();
          }
        }
      },
    );
  }
}
