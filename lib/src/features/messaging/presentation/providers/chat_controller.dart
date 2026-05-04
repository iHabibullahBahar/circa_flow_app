import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:circa_flow_main/src/features/auth/presentation/providers/session_controller.dart';
import 'package:circa_flow_main/src/features/messaging/data/repositories/chat_repository.dart';
import 'package:circa_flow_main/src/features/messaging/presentation/providers/socket_manager.dart';
import '../../data/models/conversation_model.dart';

/// GetxController that backs a single chat screen.
///
/// Named [ConversationController] to avoid collision with
/// flutter_chat_core's [ChatController] abstract interface.
///
/// Registered with tag 'chat_{conversationId}' so SocketManager can dispatch
/// WS events to it. Uses [InMemoryChatController] from flutter_chat_core as
/// the message list source of truth.
class ConversationController extends GetxController {
  final ConversationModel conversation;
  final ChatRepository _repository;
  final _picker = ImagePicker();

  ConversationController({
    required this.conversation,
    ChatRepository? repository,
  }) : _repository = repository ?? ChatRepository();

  late final InMemoryChatController chatController;

  final isLoading = true.obs;
  final isSending = false.obs;
  final isLoadingMore = false.obs;
  final hasMoreMessages = true.obs;

  /// Presence: whether any other participant in this conversation is currently online.
  final isOtherOnline = false.obs;
  final otherLastSeenAt = Rx<String?>(null);

  Timer? _presenceTimer;
  int? _oldestMessageId;
  List<int> _otherMemberIds = []; // cached after first members fetch

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    chatController = InMemoryChatController();
    _loadMessages();
    _startPresencePolling();

    // Subscribe to conversation WS channel
    try {
      Get.find<SocketManager>()
          .subscribe('private-conversation.${conversation.id}');
    } catch (_) {}
  }

  @override
  void onClose() {
    _presenceTimer?.cancel();
    chatController.dispose();

    try {
      Get.find<SocketManager>()
          .unsubscribe('private-conversation.${conversation.id}');
    } catch (_) {}

    super.onClose();
  }

  // ── Data Loading ───────────────────────────────────────────────────────────

  Future<void> _loadMessages() async {
    isLoading.value = true;
    final result =
        await _repository.getMessages(conversationId: conversation.id);

    result.fold(
      (failure) => isLoading.value = false,
      (rawList) async {
        final messages =
            rawList.map(_mapToMessage).whereType<Message>().toList();
        if (messages.isNotEmpty) {
          _oldestMessageId = _extractId(rawList.first);
          await chatController.insertAllMessages(messages);
          _markRead(messages.last);
        }
        hasMoreMessages.value = rawList.length >= 50; // backend initial limit = 50
        isLoading.value = false;
      },
    );
  }

  /// Loads older messages when user scrolls to top.
  Future<void> loadMoreMessages() async {
    if (isLoadingMore.value || !hasMoreMessages.value) return;
    if (_oldestMessageId == null) return;

    isLoadingMore.value = true;
    final result = await _repository.getMessages(
      conversationId: conversation.id,
      oldestId: _oldestMessageId, // fixed: was beforeId
    );

    result.fold(
      (failure) => isLoadingMore.value = false,
      (rawList) async {
        if (rawList.isEmpty) {
          hasMoreMessages.value = false;
        } else {
          _oldestMessageId = _extractId(rawList.first);
          final older =
              rawList.map(_mapToMessage).whereType<Message>().toList();
          await chatController.insertAllMessages(older, index: 0);
          hasMoreMessages.value = rawList.length >= 20;
        }
        isLoadingMore.value = false;
      },
    );
  }

  // ── Send ───────────────────────────────────────────────────────────────────

  Future<void> onMessageSend(String text) async {
    if (text.trim().isEmpty) return;
    isSending.value = true;

    // Optimistic insert
    final optimistic = _optimisticTextMessage(text);
    await chatController.insertMessage(optimistic);

    final result = await _repository.sendText(
      conversationId: conversation.id,
      text: text.trim(),
    );

    result.fold(
      (failure) async {
        // Replace optimistic with failed state
        await chatController.updateMessage(
          optimistic,
          optimistic.copyWith(status: MessageStatus.error),
        );
        isSending.value = false;
      },
      (raw) async {
        final confirmed = _mapToMessage(raw);
        if (confirmed != null) {
          await chatController.updateMessage(optimistic, confirmed);
          _markRead(confirmed);
        }
        isSending.value = false;
      },
    );
  }

  /// Show a bottom sheet to pick an image from gallery or camera, then send.
  Future<void> pickAndSendImage() async {
    final source = await _showImageSourceSheet();
    if (source == null) return;

    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1920,
    );
    if (picked == null) return;

    isSending.value = true;

    // Optimistic image preview using local file path
    final optimistic = _optimisticImageMessage(picked.path);
    await chatController.insertMessage(optimistic);

    final result = await _repository.sendImage(
      conversationId: conversation.id,
      filePath: picked.path,
    );

    result.fold(
      (failure) async {
        await chatController.updateMessage(
          optimistic,
          optimistic.copyWith(status: MessageStatus.error),
        );
        isSending.value = false;
      },
      (raw) async {
        // Replace optimistic local preview with server CDN URL
        final confirmed = _mapToMessage(raw);
        if (confirmed != null) {
          await chatController.updateMessage(optimistic, confirmed);
          _markRead(confirmed);
        }
        isSending.value = false;
      },
    );
  }

  Future<ImageSource?> _showImageSourceSheet() async {
    return Get.bottomSheet<ImageSource>(
      Container(
        decoration: BoxDecoration(
          color: Get.theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Get.theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Get.theme.colorScheme.primaryContainer,
                  child: Icon(Icons.photo_library_rounded,
                      color: Get.theme.colorScheme.onPrimaryContainer),
                ),
                title: const Text('Choose from Gallery'),
                onTap: () => Get.back<ImageSource>(result: ImageSource.gallery),
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Get.theme.colorScheme.secondaryContainer,
                  child: Icon(Icons.camera_alt_rounded,
                      color: Get.theme.colorScheme.onSecondaryContainer),
                ),
                title: const Text('Take a Photo'),
                onTap: () => Get.back<ImageSource>(result: ImageSource.camera),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }


  // ── WS Event handlers ─────────────────────────────────────────────────────

  void onSocketMessageNew(Map<String, dynamic> payload) {
    final messageId = payload['message_id'];
    if (messageId == null) return;
    _fetchAndInsertMessage(messageId as int);
  }

  void onSocketMessageRead(Map<String, dynamic> payload) {
    // Phase 2: update seenAt on individual messages
  }


  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<void> _fetchAndInsertMessage(int messageId) async {
    final alreadyExists = chatController.messages
        .any((m) => m.id == messageId.toString());
    if (alreadyExists) return;

    // Fetch 1 newest message using newestId - 1 workaround for single-message fetch
    final result = await _repository.getMessages(
      conversationId: conversation.id,
      newestId: messageId - 1, // gets messages newer than (messageId-1) → includes messageId
    );

    result.fold(
      (failure) => null,
      (rawList) async {
        if (rawList.isEmpty) return;
        // Find the specific message
        final targetRaw = rawList.firstWhere(
          (r) => (r['id'] as num?)?.toInt() == messageId,
          orElse: () => rawList.last,
        );
        final msg = _mapToMessage(targetRaw);
        if (msg != null &&
            !chatController.messages.any((m) => m.id == msg.id)) {
          await chatController.insertMessage(msg);
          _markRead(msg);
        }
      },
    );
  }

  void _markRead(Message message) {
    final id = int.tryParse(message.id);
    if (id == null) return;
    _repository.markRead(
        conversationId: conversation.id, messageId: id);
  }

  Message? _mapToMessage(Map<String, dynamic> raw) {
    try {
      final id = (raw['id'] as num).toInt().toString();
      // Panel messages (sent_from_panel = true) may have sender_id = null
      final rawSenderId = raw['sender_id'];
      final authorId = rawSenderId != null
          ? (rawSenderId as num).toInt().toString()
          : 'panel'; // panel-sent messages get a virtual 'panel' author
      final type = (raw['type'] as String?) ?? 'text';
      final createdAt = raw['created_at'] != null
          ? DateTime.tryParse(raw['created_at'] as String)
          : null;

      // Store panel badge info in metadata for the message bubble builder
      final metaRaw = (raw['metadata'] as Map<String, dynamic>?) ?? {};
      final metadata = <String, dynamic>{
        if (raw['sender_name'] != null) 'sender_name': raw['sender_name'],
        if (raw['sender_panel_role'] != null)
          'sender_panel_role': raw['sender_panel_role'],
        if (metaRaw['sent_from_panel'] == true) 'sent_from_panel': true,
      };

      if (type == 'image') {
        return Message.image(
          id: id,
          authorId: authorId,
          source: (raw['content'] as String?) ?? '',
          createdAt: createdAt,
          status: MessageStatus.sent,
          metadata: metadata.isNotEmpty ? metadata : null,
        );
      }

      return Message.text(
        id: id,
        authorId: authorId,
        text: (raw['content'] as String?) ?? '',
        createdAt: createdAt,
        status: MessageStatus.sent,
        metadata: metadata.isNotEmpty ? metadata : null,
      );
    } catch (_) {
      return null;
    }
  }

  Message _optimisticTextMessage(String text) {
    final currentUserId =
        Get.find<SessionController>().user.value?.id ?? 'me';
    return Message.text(
      id: 'opt_${DateTime.now().millisecondsSinceEpoch}',
      authorId: currentUserId,
      text: text,
      createdAt: DateTime.now(),
      status: MessageStatus.sending,
    );
  }

  /// Optimistic image message using local file path as the source.
  /// The flutter_chat_ui Image widget checks if source is a valid URL;
  /// for local files we use the `file://` scheme via File.uri.toString().
  Message _optimisticImageMessage(String localPath) {
    final currentUserId =
        Get.find<SessionController>().user.value?.id ?? 'me';
    return Message.image(
      id: 'opt_img_${DateTime.now().millisecondsSinceEpoch}',
      authorId: currentUserId,
      source: File(localPath).uri.toString(), // file:// URI for local display
      createdAt: DateTime.now(),
      status: MessageStatus.sending,
    );
  }

  // ── Presence ───────────────────────────────────────────────────────────────

  void _startPresencePolling() {
    _fetchPresence(); // immediate first poll
    // Poll every 90 seconds (server window is 120s so 90s keeps it fresh)
    _presenceTimer = Timer.periodic(
      const Duration(seconds: 90),
      (_) => _fetchPresence(),
    );
  }

  Future<void> _fetchPresence() async {
    final me = Get.find<SessionController>().user.value?.id;

    // On first call: fetch members from API to build the ID list
    if (_otherMemberIds.isEmpty) {
      final membersResult =
          await _repository.getMembers(conversationId: conversation.id);
      membersResult.fold(
        (_) => null,
        (rawList) {
          _otherMemberIds = rawList
              .map((r) => (r['member_id'] as num?)?.toInt())
              .whereType<int>()
              .where((id) => id.toString() != me)
              .toList();
        },
      );
    }

    if (_otherMemberIds.isEmpty) return;

    final result =
        await _repository.fetchPresence(memberIds: _otherMemberIds);
    result.fold(
      (_) => null,
      (presenceMap) {
        bool anyOnline = false;
        String? lastSeen;
        for (final id in _otherMemberIds) {
          final p = presenceMap[id.toString()] as Map<String, dynamic>?;
          if (p == null) continue;
          if (p['online'] == true) {
            anyOnline = true;
            break;
          }
          final seen = p['last_seen_at'] as String?;
          if (seen != null && lastSeen == null) lastSeen = seen;
        }
        isOtherOnline.value = anyOnline;
        if (!anyOnline) otherLastSeenAt.value = lastSeen;
      },
    );
  }

  int? _extractId(Map<String, dynamic> raw) =>
      (raw['id'] as num?)?.toInt();
}
