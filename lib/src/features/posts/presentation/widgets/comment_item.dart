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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAvatar(widget.comment.author, size: 36),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Comment Bubble ---
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F3F5),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.comment.author?.fullName ?? 'Anonymous',
                          style: TextStyle(
                            fontWeight: FontWeight.w900, 
                            fontSize: 13.sp,
                            color: Colors.black87,
                          ),
                        ),
                        const Gap(2),
                        Text(
                          widget.comment.content,
                          style: TextStyle(
                            color: Colors.black87, 
                            fontSize: 14.sp, 
                            height: 1.3,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // --- Actions ---
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 4),
                    child: Row(
                      children: [
                        Text(
                          _formatTime(widget.comment.createdAt),
                          style: TextStyle(color: Colors.black38, fontSize: 11.sp, fontWeight: FontWeight.w600),
                        ),
                        const Gap(16),
                        InkWell(
                          onTap: () {
                            // Placeholder for Like
                          },
                          child: Text(
                            'Like',
                            style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w800, fontSize: 11.sp),
                          ),
                        ),
                        const Gap(16),
                        InkWell(
                          onTap: () => widget.onReply(widget.comment, (newReply) {
                            setState(() {
                              if (!_showReplies) {
                                _showReplies = true;
                              }
                              if (!_replies.contains(newReply)) {
                                _replies.add(newReply);
                              }
                            });
                          }),
                          child: Text(
                            'Reply',
                            style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w800, fontSize: 11.sp),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (widget.comment.repliesCount > 0 && !_showReplies)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 8),
                      child: InkWell(
                        onTap: _toggleReplies,
                        child: Row(
                          children: [
                            Container(width: 24, height: 1, color: Colors.black12),
                            const Gap(8),
                            Text(
                              'View ${widget.comment.repliesCount} replies',
                              style: TextStyle(color: Colors.black45, fontWeight: FontWeight.w700, fontSize: 12.sp),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (_showReplies) ...[
          Padding(
            padding: const EdgeInsets.only(left: 48, top: 12),
            child: _isLoadingReplies
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Column(
                  children: [
                    ..._replies.map((r) => ReplyItem(reply: r)),
                    if (_showReplies)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: InkWell(
                          onTap: () => setState(() => _showReplies = false),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              'Hide replies',
                              style: TextStyle(color: Colors.black45, fontWeight: FontWeight.w700, fontSize: 11.sp),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
          ),
        ],
      ],
    );
  }

  Widget _buildAvatar(CommentAuthor? author, {double size = 36}) {
    final cs = context.contextTheme.colorScheme;
    if (author?.avatarPath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: AppCachedImage(
          imageUrl: author!.avatarPath!,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: cs.primary.withValues(alpha: 0.1),
      child: Text(
        author?.firstName.substring(0, 1).toUpperCase() ?? '?',
        style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold, fontSize: size * 0.4),
      ),
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

    try {
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
    if (diff.inSeconds < 60) return 'now';
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(context, reply.author, size: 28),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F3F5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reply.author?.fullName ?? 'Anonymous',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.sp, color: Colors.black87),
                      ),
                      const Gap(1),
                      Text(
                        reply.content,
                        style: TextStyle(color: Colors.black87, fontSize: 13.sp, height: 1.3, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 2),
                  child: Row(
                    children: [
                      Text(
                        _formatTime(reply.createdAt),
                        style: TextStyle(color: Colors.black38, fontSize: 10.sp, fontWeight: FontWeight.w600),
                      ),
                      const Gap(12),
                      Text(
                        'Like',
                        style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w800, fontSize: 10.sp),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, CommentAuthor? author, {double size = 28}) {
    final cs = context.contextTheme.colorScheme;
    if (author?.avatarPath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: AppCachedImage(
          imageUrl: author!.avatarPath!,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: cs.primary.withValues(alpha: 0.1),
      child: Text(
        author?.firstName.substring(0, 1).toUpperCase() ?? '?',
        style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold, fontSize: size * 0.4),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
