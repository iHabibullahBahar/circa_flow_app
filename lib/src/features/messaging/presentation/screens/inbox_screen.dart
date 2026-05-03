import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:circa_flow_main/src/routing/app_routes.dart';
import '../../data/models/conversation_model.dart';
import '../providers/inbox_controller.dart';
import 'widgets/inbox_item.dart';

/// Inbox screen — shows sorted list of all conversations for the member.
/// Supports pull-to-refresh and WS-driven live updates.
class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // InboxController is injected by InboxBinding when this route is pushed.
    final controller = Get.find<InboxController>(tag: 'inbox_controller');
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        title: Text(
          'Messages',
          style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded),
            tooltip: 'New conversation',
            onPressed: () => _showNewConversationSheet(context, controller),
          ),
        ],
      ),
      body: Obx(() {
        final loading = controller.isLoading.value;
        final inbox = controller.sortedInbox;

        // Skeleton loading state
        if (loading && inbox.isEmpty) {
          return Skeletonizer(
            enabled: true,
            child: ListView.separated(
              itemCount: 7,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 68),
              itemBuilder: (_, __) => InboxItem(
                conversation: _mockConversation(),
                onTap: () {},
              ),
            ),
          );
        }

        // Empty state
        if (!loading && inbox.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 64,
                  color: cs.outlineVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'No conversations yet',
                  style: tt.titleMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start a conversation with a fellow member',
                  style: tt.bodySmall?.copyWith(color: cs.outlineVariant),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('New Message'),
                  onPressed: () =>
                      _showNewConversationSheet(context, controller),
                ),
              ],
            ),
          );
        }

        // Inbox list
        return RefreshIndicator(
          onRefresh: controller.refresh,
          color: cs.primary,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: inbox.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 68, endIndent: 16),
            itemBuilder: (_, index) {
              final conv = inbox[index];
              return InboxItem(
                key: ValueKey(conv.id),
                conversation: conv,
                onTap: () => _openChat(conv),
              );
            },
          ),
        );
      }),
    );
  }

  void _openChat(ConversationModel conversation) {
    Get.toNamed<void>(
      AppRoutes.chat,
      arguments: conversation,
    );
  }

  void _showNewConversationSheet(
    BuildContext context,
    InboxController controller,
  ) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    Get.bottomSheet<void>(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New Conversation',
                style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            // Direct message option
            ListTile(
              leading: CircleAvatar(
                backgroundColor: cs.primaryContainer,
                child: Icon(Icons.person_rounded,
                    color: cs.onPrimaryContainer),
              ),
              title: const Text('Direct Message'),
              subtitle: const Text('Message a specific member'),
              onTap: () {
                Get.back<void>();
                // TODO Phase 1D: Navigate to member picker → startDirect
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: cs.secondaryContainer,
                child: Icon(Icons.group_rounded,
                    color: cs.onSecondaryContainer),
              ),
              title: const Text('Group Chat'),
              subtitle: const Text('Create a group with multiple members'),
              onTap: () {
                Get.back<void>();
                // TODO Phase 1D: Navigate to member picker → createGroup
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Dummy conversation for Skeletonizer (never shown to user).
  ConversationModel _mockConversation() {
    return ConversationModel(
      id: 0,
      type: 'direct',
      name: 'Loading member name here',
      lastMessage: 'This is a placeholder message text...',
      lastMessageType: 'text',
      lastMessageAt: DateTime.now().subtract(const Duration(minutes: 5)),
      unreadCount: 2,
      updatedAt: DateTime.now(),
    );
  }
}
