import 'package:circa_flow_main/src/imports/imports.dart';
import '../../data/models/comment_model.dart';
import '../providers/comments_controller.dart';

class CommentItem extends StatefulWidget {
  final CommentModel comment;
  final void Function(CommentModel, void Function(CommentModel)) onReply;

  const CommentItem({super.key, required this.comment, required this.onReply});

  @override
  State<CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends State<CommentItem> {
  bool _showReplies = false;
  List<CommentModel> _replies = [];
  bool _isLoadingReplies = false;

  @override
  Widget build(BuildContext context) {
    final cs = context.contextTheme.colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: cs.primary.withValues(alpha: 0.1),
              child: Text(
                widget.comment.author?.firstName.substring(0, 1).toUpperCase() ?? '?',
                style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.comment.author?.fullName ?? 'Anonymous',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.sp),
                      ),
                      const Gap(8),
                      Text(
                        _formatTime(widget.comment.createdAt),
                        style: TextStyle(color: Colors.black26, fontSize: 10.sp),
                      ),
                    ],
                  ),
                  const Gap(4),
                  Text(
                    widget.comment.content,
                    style: TextStyle(color: Colors.black87, fontSize: 14.sp, height: 1.4),
                  ),
                  const Gap(8),
                  Row(
                    children: [
                      InkWell(
                        onTap: () => widget.onReply(widget.comment, (newReply) {
                          setState(() {
                            if (!_showReplies) {
                              _showReplies = true;
                            }
                            _replies.add(newReply);
                          });
                        }),
                        child: Text(
                          'Reply',
                          style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold, fontSize: 12.sp),
                        ),
                      ),
                      if (widget.comment.repliesCount > 0) ...[
                        const Gap(16),
                        InkWell(
                          onTap: _toggleReplies,
                          child: Text(
                            _showReplies ? 'Hide replies' : 'View ${widget.comment.repliesCount} replies',
                            style: TextStyle(color: Colors.black45, fontWeight: FontWeight.w600, fontSize: 12.sp),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_showReplies) ...[
          Padding(
            padding: const EdgeInsets.only(left: 48, top: 16),
            child: _isLoadingReplies
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Column(
                  children: _replies.map((r) => ReplyItem(reply: r)).toList(),
                ),
          ),
        ],
      ],
    );
  }

  void _toggleReplies() async {
    if (_showReplies) {
      setState(() => _showReplies = false);
      return;
    }

    setState(() {
      _showReplies = true;
      _isLoadingReplies = true;
    });

    // In a real app, we might want to pass the controller or a callback to fetch replies
    // For now, we'll try to find the controller via GetX
    try {
      // Fallback: just use standard Get.find if only one CommentsController exists
      final replies = await Get.find<CommentsController>(tag: widget.comment.id.toString()).fetchReplies(widget.comment.id);
      
      setState(() {
        _replies = replies;
        _isLoadingReplies = false;
      });
    } catch (e) {
      setState(() => _isLoadingReplies = false);
    }
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

class ReplyItem extends StatelessWidget {
  final CommentModel reply;
  const ReplyItem({super.key, required this.reply});

  @override
  Widget build(BuildContext context) {
    final cs = context.contextTheme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: cs.primary.withValues(alpha: 0.05),
            child: Text(
              reply.author?.firstName.substring(0, 1).toUpperCase() ?? '?',
              style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold, fontSize: 10),
            ),
          ),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      reply.author?.fullName ?? 'Anonymous',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.sp),
                    ),
                    const Gap(6),
                    Text(
                      'Just now', // Simplified
                      style: TextStyle(color: Colors.black26, fontSize: 9.sp),
                    ),
                  ],
                ),
                const Gap(2),
                Text(
                  reply.content,
                  style: TextStyle(color: Colors.black87, fontSize: 13.sp, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
