import 'package:equatable/equatable.dart';

class CommentModel extends Equatable {
  final int id;
  final int userId;
  final String content;
  final int? parentId;
  final CommentAuthor? author;
  final int repliesCount;
  final bool isEdited;
  final DateTime createdAt;

  const CommentModel({
    required this.id,
    required this.userId,
    required this.content,
    this.parentId,
    this.author,
    this.repliesCount = 0,
    this.isEdited = false,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      content: json['content'] as String? ?? '',
      parentId: json['parent_id'] != null ? (json['parent_id'] as num).toInt() : null,
      author: json['author'] != null ? CommentAuthor.fromJson(json['author'] as Map<String, dynamic>) : null,
      repliesCount: (json['replies_count'] as num?)?.toInt() ?? 0,
      isEdited: (json['is_edited'] as bool?) ?? false,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }

  bool get isReply => parentId != null;

  @override
  List<Object?> get props => [id, userId, content, parentId, author, repliesCount, isEdited, createdAt];
}

class CommentAuthor extends Equatable {
  final int id;
  final String name;
  final String? avatarPath;

  const CommentAuthor({
    required this.id,
    required this.name,
    this.avatarPath,
  });

  factory CommentAuthor.fromJson(Map<String, dynamic> json) {
    return CommentAuthor(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? json['full_name'] as String? ?? '',
      avatarPath: json['avatar_path'] as String?,
    );
  }

  String get fullName => name;
  String get firstName => name.split(' ').first;
  String get lastName => name.contains(' ') ? name.split(' ').last : '';

  @override
  List<Object?> get props => [id, name, avatarPath];
}
