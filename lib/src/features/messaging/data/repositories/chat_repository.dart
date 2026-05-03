import 'package:circa_flow_main/src/config/api_endpoints.dart';
import 'package:circa_flow_main/src/imports/core_imports.dart';
import 'package:circa_flow_main/src/services/api_service.dart';
import 'package:fpdart/fpdart.dart';

class ChatRepository {
  final ApiService _api = ApiService.instance;

  /// Fetch paginated messages for a conversation.
  /// [oldestId] — load messages older than this ID (scroll-up pagination cursor).
  /// [newestId] — catch-up: all messages newer than this ID.
  FutureEither<List<Map<String, dynamic>>> getMessages({
    required int conversationId,
    int? oldestId,
    int? newestId,
  }) async {
    final result = await _api.post<Map<String, dynamic>>(
      zMessagingMessagesEndpoint,
      data: {
        'conversation_id': conversationId,
        if (oldestId != null) 'oldest_id': oldestId,
        if (newestId != null) 'newest_id': newestId,
      },
    );

    return result.map((response) {
      final List<dynamic> data =
          (response['data'] as List<dynamic>?) ?? [];
      return data.whereType<Map<String, dynamic>>().toList();
    });
  }

  /// Send a text message in a conversation.
  FutureEither<Map<String, dynamic>> sendText({
    required int conversationId,
    required String text,
  }) async {
    final result = await _api.post<Map<String, dynamic>>(
      zMessagingSendEndpoint,
      data: {
        'conversation_id': conversationId,
        'type': 'text',
        'content': text, // backend field is 'content'
      },
    );

    return result.map((response) =>
        (response['data'] as Map<String, dynamic>?) ?? {});
  }

  /// Send an image message. [filePath] is the local file path.
  FutureEither<Map<String, dynamic>> sendImage({
    required int conversationId,
    required String filePath,
  }) async {
    final result = await _api.uploadFile<Map<String, dynamic>>(
      zMessagingSendEndpoint,
      filePath: filePath,
      fieldName: 'file', // backend expects 'file'
      extraData: {
        'conversation_id': conversationId.toString(),
        'type': 'image',
      },
    );

    return result.map((response) =>
        (response['data'] as Map<String, dynamic>?) ?? {});
  }

  /// Mark messages read up to [messageId]. Fire-and-forget — dispatched
  /// as a background job on the backend so the response is instant.
  FutureEither<void> markRead({
    required int conversationId,
    required int messageId,
  }) async {
    return _api.post<void>(
      zMessagingReadEndpoint,
      data: {
        'conversation_id': conversationId,
        'message_id': messageId,
      },
    );
  }

  /// Send typing indicator event.
  FutureEither<void> sendTyping({
    required int conversationId,
    required bool isTyping,
  }) async {
    return _api.post<void>(
      zMessagingTypingEndpoint,
      data: {
        'conversation_id': conversationId,
        'is_typing': isTyping,
      },
    );
  }

  /// Fetch presence for a list of member IDs.
  /// Returns map of memberId → {online: bool, last_seen_at: String?}
  FutureEither<Map<String, dynamic>> fetchPresence({
    required List<int> memberIds,
  }) async {
    if (memberIds.isEmpty) {
      return Right({});
    }
    final result = await _api.post<Map<String, dynamic>>(
      zMessagingPresenceEndpoint,
      data: {'member_ids': memberIds},
    );
    return result.map((response) =>
        (response['data'] as Map<String, dynamic>?) ?? {});
  }

  /// Fetch conversation members with presence info.
  FutureEither<List<Map<String, dynamic>>> getMembers({
    required int conversationId,
  }) async {
    final result = await _api.post<Map<String, dynamic>>(
      zMessagingMembersEndpoint,
      data: {'conversation_id': conversationId},
    );
    return result.map((response) {
      final List<dynamic> data = (response['data'] as List<dynamic>?) ?? [];
      return data.whereType<Map<String, dynamic>>().toList();
    });
  }
}
