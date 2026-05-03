import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../data/models/conversation_model.dart';

/// A single row in the inbox list.
/// Shows avatar, name, last message preview, unread badge, and timestamp.
class InboxItem extends StatelessWidget {
  final ConversationModel conversation;
  final VoidCallback onTap;

  const InboxItem({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final hasUnread = conversation.hasUnread;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // ── Avatar ─────────────────────────────────────────────────
            _Avatar(
              conversation: conversation,
              colorScheme: cs,
            ),
            const SizedBox(width: 12),

            // ── Name + Message Preview ─────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.name,
                          style: tt.titleSmall?.copyWith(
                            fontWeight: hasUnread
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: cs.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conversation.lastMessageAt != null)
                        Text(
                          timeago.format(conversation.lastMessageAt!,
                              allowFromNow: true),
                          style: tt.labelSmall?.copyWith(
                            color: hasUnread
                                ? cs.primary
                                : cs.onSurfaceVariant,
                            fontWeight: hasUnread
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.lastMessagePreview.isNotEmpty
                              ? conversation.lastMessagePreview
                              : 'No messages yet',
                          style: tt.bodySmall?.copyWith(
                            color: hasUnread
                                ? cs.onSurface
                                : cs.onSurfaceVariant,
                            fontWeight: hasUnread
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread) _UnreadBadge(count: conversation.unreadCount, cs: cs),
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

class _Avatar extends StatelessWidget {
  final ConversationModel conversation;
  final ColorScheme colorScheme;

  const _Avatar({required this.conversation, required this.colorScheme});

  IconData get _typeIcon {
    return switch (conversation.type) {
      'group' => Icons.group_rounded,
      'community' => Icons.people_rounded,
      'broadcast' => Icons.campaign_rounded,
      'support' => Icons.support_agent_rounded,
      _ => Icons.person_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 26,
      backgroundColor: colorScheme.primaryContainer,
      backgroundImage: conversation.avatarUrl != null
          ? NetworkImage(conversation.avatarUrl!)
          : null,
      child: conversation.avatarUrl == null
          ? Icon(_typeIcon, color: colorScheme.onPrimaryContainer, size: 24)
          : null,
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  final int count;
  final ColorScheme cs;

  const _UnreadBadge({required this.count, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: TextStyle(
          color: cs.onPrimary,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
