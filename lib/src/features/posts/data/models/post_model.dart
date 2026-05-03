/// Data model for a Post, typed against PostResource from the backend.
class PostModel {
  final int id;
  final String title;
  final String slug;
  final String? body;
  final String? coverImage;
  final List<String> images;
  final List<PostLink> links;
  final int reactionCount;
  final int commentsCount;
  final bool isLiked;
  final String? publishedAt;

  const PostModel({
    required this.id,
    required this.title,
    required this.slug,
    this.body,
    this.coverImage,
    this.images = const [],
    this.links = const [],
    this.reactionCount = 0,
    this.commentsCount = 0,
    this.isLiked = false,
    this.publishedAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> j) => PostModel(
        id: (j['id'] as num).toInt(),
        title: (j['title'] as String?) ?? '',
        slug: (j['slug'] as String?) ?? '',
        body: j['body'] as String?,
        coverImage: j['cover_image'] as String?,
        images: (j['images'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        links: (j['links'] as List<dynamic>?)
                ?.whereType<Map<String, dynamic>>()
                .map(PostLink.fromJson)
                .toList() ??
            [],
        reactionCount: (j['reaction_count'] as num?)?.toInt() ?? 0,
        commentsCount: (j['comments_count'] as num?)?.toInt() ?? 0,
        isLiked: (j['is_liked'] as bool?) ?? false,
        publishedAt: j['published_at'] as String?,
      );

  PostModel copyWith({
    int? id,
    String? title,
    String? slug,
    String? body,
    String? coverImage,
    List<String>? images,
    List<PostLink>? links,
    int? reactionCount,
    int? commentsCount,
    bool? isLiked,
    String? publishedAt,
  }) {
    return PostModel(
      id: id ?? this.id,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      body: body ?? this.body,
      coverImage: coverImage ?? this.coverImage,
      images: images ?? this.images,
      links: links ?? this.links,
      reactionCount: reactionCount ?? this.reactionCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLiked: isLiked ?? this.isLiked,
      publishedAt: publishedAt ?? this.publishedAt,
    );
  }

  String get formattedDate {
    if (publishedAt == null) return '';
    try {
      final dt = DateTime.parse(publishedAt!).toLocal();
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      final time = '$hour:${dt.minute.toString().padLeft(2, '0')} $ampm';
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $time';
    } catch (_) {
      return publishedAt ?? '';
    }
  }
}

/// A single link attached to a Post or Event.
class PostLink {
  final String url;
  final String label;
  final String target; // 'app' or 'browser'

  const PostLink({
    required this.url,
    required this.label,
    this.target = 'app',
  });

  factory PostLink.fromJson(Map<String, dynamic> j) => PostLink(
        url: (j['url'] as String?) ?? '',
        label: (j['label'] as String?) ?? 'Link',
        target: (j['target'] as String?) ?? 'app',
      );
}
