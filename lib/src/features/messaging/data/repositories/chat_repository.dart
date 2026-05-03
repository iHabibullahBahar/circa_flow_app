import 'package:circa_flow_main/src/imports/core_imports.dart';
import 'package:circa_flow_main/src/config/api_endpoints.dart';
import 'package:circa_flow_main/src/services/api_service.dart';

class ChatRepository {
  final ApiService _api = ApiService.instance;

  /// Fetch paginated messages for a conversation.
  /// [beforeId] — load messages older than this ID (pagination cursor).
  FutureEither<List<Map<String, dynamic>>> getMessages({
    required int conversationId,
    int? beforeId,
    int perPage = 30,
  }) async {
    final result = await _api.post<Map<String, dynamic>>(
      zMessagingMessagesEndpoint,
      data: {
        'conversation_id': conversationId,
        if (beforeId != null) 'before_id': beforeId,
        'per_page': perPage,
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
        'body': text,
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
      fieldName: 'image',
      extraData: {
        'conversation_id': conversationId,
        'type': 'image',
      },
    );

    return result.map((response) =>
        (response['data'] as Map<String, dynamic>?) ?? {});
  }

  /// Mark messages read up to [messageId].
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
}
