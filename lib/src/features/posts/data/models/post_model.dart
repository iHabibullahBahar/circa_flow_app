/// Data model for a Post, typed against PostResource from the backend.
class PostModel {
  final int id;
  final String title;
  final String slug;
  final String? body;
  final String? coverImage;
  final List<String> images;
  final String? publishedAt;

  const PostModel({
    required this.id,
    required this.title,
    required this.slug,
    this.body,
    this.coverImage,
    this.images = const [],
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
        publishedAt: j['published_at'] as String?,
      );
}
