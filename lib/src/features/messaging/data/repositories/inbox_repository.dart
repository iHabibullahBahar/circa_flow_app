import 'package:circa_flow_main/src/imports/core_imports.dart';
import 'package:circa_flow_main/src/config/api_endpoints.dart';
import 'package:circa_flow_main/src/services/api_service.dart';
import '../models/conversation_model.dart';

class InboxRepository {
  final ApiService _api = ApiService.instance;

  /// Fetch inbox. Optionally pass [updatedAfter] ISO timestamp for delta sync.
  FutureEither<List<ConversationModel>> getInbox({String? updatedAfter}) async {
    final result = await _api.post<Map<String, dynamic>>(
      zMessagingInboxEndpoint,
      data: {
        if (updatedAfter != null) 'updated_after': updatedAfter,
      },
    );

    return result.map((response) {
      final List<dynamic> data =
          (response['data'] as List<dynamic>?) ?? [];
      return data
          .whereType<Map<String, dynamic>>()
          .map((json) => ConversationModel.fromJson(json))
          .toList();
    });
  }

  /// Start or find a direct conversation with another member.
  FutureEither<ConversationModel> startDirect({required int memberId}) async {
    final result = await _api.post<Map<String, dynamic>>(
      zMessagingDirectEndpoint,
      data: {'member_id': memberId},
    );

    return result.map((response) {
      final data = response['data'] as Map<String, dynamic>;
      // Server returns minimal shape; build a placeholder ConversationModel.
      return ConversationModel(
        id: (data['conversation_id'] as num).toInt(),
        type: (data['type'] as String?) ?? 'direct',
        name: 'Direct Message',
        updatedAt: DateTime.now(),
      );
    });
  }

  /// Create a new group conversation.
  FutureEither<ConversationModel> createGroup({
    required String name,
    required List<int> memberIds,
  }) async {
    final result = await _api.post<Map<String, dynamic>>(
      zMessagingGroupEndpoint,
      data: {'name': name, 'member_ids': memberIds},
    );

    return result.map((response) {
      final data = response['data'] as Map<String, dynamic>;
      return ConversationModel(
        id: (data['conversation_id'] as num).toInt(),
        type: (data['type'] as String?) ?? 'group',
        name: (data['name'] as String?) ?? name,
        updatedAt: DateTime.now(),
      );
    });
  }

  /// Toggle the authenticated member's DM privacy setting.
  FutureEither<void> updateDmSetting({required bool allowDms}) async {
    return _api.post<void>(
      zMessagingDmSettingEndpoint,
      data: {'allow_dms': allowDms},
    );
  }
}
