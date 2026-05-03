import 'dart:async';
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
  final typingMemberName = Rx<String?>(null);

  Timer? _typingTimer;
  Timer? _typingClearTimer;
  int? _oldestMessageId;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    chatController = InMemoryChatController();
    _loadMessages();

    // Subscribe to conversation WS channel
    try {
      Get.find<SocketManager>()
          .subscribe('private-conversation.${conversation.id}');
    } catch (_) {}
  }

  @override
  void onClose() {
    _typingTimer?.cancel();
    _typingClearTimer?.cancel();
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
        hasMoreMessages.value = rawList.length >= 30;
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
      beforeId: _oldestMessageId,
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
          hasMoreMessages.value = rawList.length >= 30;
        }
        isLoadingMore.value = false;
      },
    );
  }

  // ── Send ───────────────────────────────────────────────────────────────────

  Future<void> onMessageSend(String text) async {
    if (text.trim().isEmpty) return;
    isSending.value = true;
    _stopTypingIndicator();

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

  /// Pick an image from gallery and send it.
  Future<void> pickAndSendImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;

    isSending.value = true;
    final result = await _repository.sendImage(
      conversationId: conversation.id,
      filePath: picked.path,
    );

    result.fold(
      (failure) => isSending.value = false,
      (raw) async {
        final msg = _mapToMessage(raw);
        if (msg != null) {
          await chatController.insertMessage(msg);
          _markRead(msg);
        }
        isSending.value = false;
      },
    );
  }

  // ── Typing ─────────────────────────────────────────────────────────────────

  void onInputChanged(String _) {
    _sendTypingIndicator(isTyping: true);
    _typingTimer?.cancel();
    _typingTimer =
        Timer(const Duration(seconds: 3), _stopTypingIndicator);
  }

  void _sendTypingIndicator({required bool isTyping}) {
    _repository.sendTyping(
        conversationId: conversation.id, isTyping: isTyping);
  }

  void _stopTypingIndicator() {
    _typingTimer?.cancel();
    _sendTypingIndicator(isTyping: false);
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

  void onSocketTyping(Map<String, dynamic> payload) {
    final currentUserId = Get.find<SessionController>().user.value?.id;
    final senderId = payload['member_id']?.toString();
    if (senderId == currentUserId) return;

    final isTyping = payload['is_typing'] == true;
    if (isTyping) {
      typingMemberName.value = payload['member_name'] as String?;
      _typingClearTimer?.cancel();
      _typingClearTimer = Timer(
          const Duration(seconds: 4), () => typingMemberName.value = null);
    } else {
      _typingClearTimer?.cancel();
      typingMemberName.value = null;
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<void> _fetchAndInsertMessage(int messageId) async {
    final alreadyExists = chatController.messages
        .any((m) => m.id == messageId.toString());
    if (alreadyExists) return;

    final result = await _repository.getMessages(
      conversationId: conversation.id,
      perPage: 1,
    );

    result.fold(
      (failure) => null,
      (rawList) async {
        if (rawList.isEmpty) return;
        final msg = _mapToMessage(rawList.last);
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
      final authorId = (raw['sender_id'] as num).toInt().toString();
      final type = (raw['type'] as String?) ?? 'text';
      final createdAt = raw['created_at'] != null
          ? DateTime.tryParse(raw['created_at'] as String)
          : null;

      if (type == 'image') {
        return Message.image(
          id: id,
          authorId: authorId,
          source: (raw['image_url'] as String?) ?? '',
          createdAt: createdAt,
          status: MessageStatus.sent,
        );
      }

      return Message.text(
        id: id,
        authorId: authorId,
        text: (raw['body'] as String?) ?? '',
        createdAt: createdAt,
        status: MessageStatus.sent,
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

  int? _extractId(Map<String, dynamic> raw) =>
      (raw['id'] as num?)?.toInt();
}
