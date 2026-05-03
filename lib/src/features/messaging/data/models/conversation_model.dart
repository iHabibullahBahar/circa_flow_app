import 'package:equatable/equatable.dart';

/// Represents a single conversation in the inbox list.
class ConversationModel extends Equatable {
  final int id;
  final String type; // direct | group | community | support | broadcast
  final String name;
  final String? avatarUrl;
  final String? lastMessage;
  final String? lastMessageType; // text | image | system
  final DateTime? lastMessageAt;
  final int unreadCount;
  final DateTime updatedAt;

  const ConversationModel({
    required this.id,
    required this.type,
    required this.name,
    this.avatarUrl,
    this.lastMessage,
    this.lastMessageType,
    this.lastMessageAt,
    this.unreadCount = 0,
    required this.updatedAt,
  });

  bool get hasUnread => unreadCount > 0;

  bool get isDirect => type == 'direct';
  bool get isGroup => type == 'group';
  bool get isCommunity => type == 'community';
  bool get isBroadcast => type == 'broadcast';

  String get lastMessagePreview {
    if (lastMessage == null) return '';
    if (lastMessageType == 'image') return '📷 Photo';
    return lastMessage!;
  }

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: (json['conversation_id'] as num).toInt(),
      type: (json['type'] as String?) ?? 'direct',
      name: (json['name'] as String?) ?? 'Unknown',
      avatarUrl: json['avatar_url'] as String?,
      lastMessage: json['last_message'] as String?,
      lastMessageType: json['last_message_type'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.tryParse(json['last_message_at'] as String)
          : null,
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      updatedAt: DateTime.tryParse((json['updated_at'] as String?) ?? '') ??
          DateTime.now(),
    );
  }

  ConversationModel copyWith({
    int? unreadCount,
    String? lastMessage,
    String? lastMessageType,
    DateTime? lastMessageAt,
    DateTime? updatedAt,
  }) {
    return ConversationModel(
      id: id,
      type: type,
      name: name,
      avatarUrl: avatarUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, type, name, lastMessage, unreadCount, updatedAt];
}
