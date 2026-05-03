import 'package:equatable/equatable.dart';

class CommentModel extends Equatable {
  final int id;
  final int userId;
  final String content;
  final int? parentId;
  final CommentAuthor? author;
  final int repliesCount;
  final int likesCount;
  final bool isLiked;
  final bool isEdited;
  final DateTime createdAt;

  const CommentModel({
    required this.id,
    required this.userId,
    required this.content,
    this.parentId,
    this.author,
    this.repliesCount = 0,
    this.likesCount = 0,
    this.isLiked = false,
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
      likesCount: (json['reaction_count'] as num?)?.toInt() ?? 0,
      isLiked: (json['is_liked'] as bool?) ?? false,
      isEdited: (json['is_edited'] as bool?) ?? false,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }

  bool get isReply => parentId != null;

  CommentModel copyWith({
    int? id,
    int? userId,
    String? content,
    int? parentId,
    CommentAuthor? author,
    int? repliesCount,
    int? likesCount,
    bool? isLiked,
    bool? isEdited,
    DateTime? createdAt,
  }) {
    return CommentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      parentId: parentId ?? this.parentId,
      author: author ?? this.author,
      repliesCount: repliesCount ?? this.repliesCount,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
      isEdited: isEdited ?? this.isEdited,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, content, parentId, author, repliesCount, likesCount, isLiked, isEdited, createdAt];
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
