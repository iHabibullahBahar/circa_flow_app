import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:get/get.dart';
import 'package:circa_flow_main/src/features/auth/presentation/providers/session_controller.dart';
import 'package:circa_flow_main/src/features/messaging/data/models/conversation_model.dart';
import '../providers/chat_controller.dart';

/// Full-screen chat screen powered by flutter_chat_ui.
///
/// Receives a [ConversationModel] via [Get.arguments] / constructor.
/// Registers [ConversationController] with tag 'chat_{conversationId}' so
/// SocketManager can dispatch WS events to it.
class ChatScreen extends StatefulWidget {
  final ConversationModel conversation;
  const ChatScreen({super.key, required this.conversation});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ConversationController _convCtrl;
  late final SessionController _session;

  @override
  void initState() {
    super.initState();
    _session = Get.find<SessionController>();

    _convCtrl = Get.put<ConversationController>(
      ConversationController(conversation: widget.conversation),
      tag: 'chat_${widget.conversation.id}',
    );
  }

  @override
  void dispose() {
    Get.delete<ConversationController>(
        tag: 'chat_${widget.conversation.id}', force: true);
    super.dispose();
  }

  // ── User resolver ──────────────────────────────────────────────────────────

  Future<User> _resolveUser(String userId) async {
    final me = _session.user.value;
    if (me != null && userId == me.id) {
      return User(
        id: userId,
        name: me.displayName,
        imageSource: me.photoUrl,
      );
    }
    return User(id: userId);
  }

  // ── Load more builder ──────────────────────────────────────────────────────

  Widget _buildLoadMore(BuildContext context) {
    return Obx(() {
      if (!_convCtrl.hasMoreMessages.value) return const SizedBox.shrink();
      return GestureDetector(
        onTap: _convCtrl.loadMoreMessages,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Load older messages',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final me = _session.user.value;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: _ChatAppBar(
        conversation: widget.conversation,
        convCtrl: _convCtrl,
      ),
      body: Obx(() {
        if (_convCtrl.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // ── Load more progress indicator ─────────────────────────────
            if (_convCtrl.isLoadingMore.value)
              LinearProgressIndicator(
                color: cs.primary,
                backgroundColor: cs.surfaceContainerHighest,
              ),

            // ── Chat list ────────────────────────────────────────────────
            Expanded(
              child: Chat(
                currentUserId: me?.id ?? '',
                resolveUser: _resolveUser,
                chatController: _convCtrl.chatController,
                theme: ChatTheme.fromThemeData(Theme.of(context)),
                onMessageSend: _convCtrl.onMessageSend,
                onAttachmentTap: _convCtrl.pickAndSendImage,
                builders: Builders(
                  loadMoreBuilder: _buildLoadMore,
                ),
              ),
            ),

            // ── Typing indicator banner ──────────────────────────────────
            Obx(() {
              final name = _convCtrl.typingMemberName.value;
              if (name == null) return const SizedBox.shrink();
              return _TypingBanner(name: name, cs: cs);
            }),
          ],
        );
      }),
    );
  }
}

// ── AppBar ────────────────────────────────────────────────────────────────────

class _ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final ConversationModel conversation;
  final ConversationController convCtrl;
  const _ChatAppBar({
    required this.conversation,
    required this.convCtrl,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return AppBar(
      backgroundColor: cs.surface,
      elevation: 0,
      titleSpacing: 0,
      leading: const BackButton(),
      title: Row(
        children: [
          // Avatar with animated online dot overlay for DMs
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: cs.primaryContainer,
                backgroundImage: conversation.avatarUrl != null
                    ? NetworkImage(conversation.avatarUrl!)
                    : null,
                child: conversation.avatarUrl == null
                    ? Icon(_typeIcon(conversation.type),
                        size: 18, color: cs.onPrimaryContainer)
                    : null,
              ),
              if (conversation.isDirect)
                Obx(() => Positioned(
                      right: -1,
                      bottom: -1,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: convCtrl.isOtherOnline.value
                              ? Colors.green
                              : Colors.grey.shade400,
                          shape: BoxShape.circle,
                          border: Border.all(color: cs.surface, width: 1.5),
                        ),
                      ),
                    )),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  conversation.name,
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // Presence subtitle
                Obx(() {
                  if (conversation.isDirect) {
                    // Typing takes priority
                    if (convCtrl.typingMemberName.value != null) {
                      return Text(
                        'typing…',
                        style: tt.labelSmall?.copyWith(
                          color: cs.primary,
                          fontStyle: FontStyle.italic,
                        ),
                      );
                    }
                    if (convCtrl.isOtherOnline.value) {
                      return Text('Online',
                          style: tt.labelSmall
                              ?.copyWith(color: Colors.green));
                    }
                    final raw = convCtrl.otherLastSeenAt.value;
                    if (raw != null) {
                      final dt = DateTime.tryParse(raw)?.toLocal();
                      final diff =
                          dt != null ? DateTime.now().difference(dt) : null;
                      final label = diff == null
                          ? 'Offline'
                          : diff.inMinutes < 60
                              ? 'Last seen ${diff.inMinutes}m ago'
                              : diff.inHours < 24
                                  ? 'Last seen ${diff.inHours}h ago'
                                  : 'Last seen ${dt!.day}/${dt.month}';
                      return Text(label,
                          style: tt.labelSmall
                              ?.copyWith(color: cs.onSurfaceVariant));
                    }
                    return Text('Offline',
                        style: tt.labelSmall
                            ?.copyWith(color: cs.onSurfaceVariant));
                  }
                  return Text(
                    '${conversation.isCommunity ? 'Community' : 'Group'} chat',
                    style:
                        tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (conversation.isGroup || conversation.isCommunity)
          IconButton(
            icon: const Icon(Icons.people_outline_rounded),
            tooltip: 'Members',
            onPressed: () {
              // TODO: show members bottom sheet
            },
          ),
      ],
    );
  }

  IconData _typeIcon(String type) => switch (type) {
        'group' => Icons.group_rounded,
        'community' => Icons.people_rounded,
        'broadcast' => Icons.campaign_rounded,
        'support' => Icons.support_agent_rounded,
        _ => Icons.person_rounded,
      };
}


// ── Typing indicator banner ────────────────────────────────────────────────────

class _TypingBanner extends StatelessWidget {
  final String name;
  final ColorScheme cs;
  const _TypingBanner({required this.name, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: cs.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          _DotsAnimation(color: cs.primary),
          const SizedBox(width: 8),
          Text(
            '$name is typing...',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
      ),
    );
  }
}

// ── Animated typing dots ───────────────────────────────────────────────────────

class _DotsAnimation extends StatefulWidget {
  final Color color;
  const _DotsAnimation({required this.color});

  @override
  State<_DotsAnimation> createState() => _DotsAnimationState();
}

class _DotsAnimationState extends State<_DotsAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final delay = i * 0.3;
          final opacity = ((_ctrl.value - delay).clamp(0.0, 0.6) / 0.6);
          return Padding(
            padding: const EdgeInsets.only(right: 3),
            child: Opacity(
              opacity: opacity.toDouble(),
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
