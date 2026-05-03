import 'package:circa_flow_main/src/imports/core_imports.dart';
import 'package:circa_flow_main/src/config/api_endpoints.dart';
import 'package:circa_flow_main/src/services/api_service.dart';
import 'package:circa_flow_main/src/shared/models/paginated_result.dart';
import '../models/post_model.dart';

class PostsRepository {
  PostsRepository._();
  static final PostsRepository instance = PostsRepository._();

  final _api = ApiService.instance;

  FutureEither<PaginatedResult<PostModel>> fetchPosts({int page = 1}) async {
    final result = await _api.post<Map<String, dynamic>>(
      zPostsEndpoint,
      data: {'page': page, 'per_page': 20},
    );
    return result.map(_mapResult);
  }

  FutureEither<PostModel> fetchPostDetails(int id) async {
    final result = await _api.post<Map<String, dynamic>>(
      zPostsShowEndpoint,
      data: {'id': id},
    );
    return result.map((res) => PostModel.fromJson(res?['data']));
  }

  FutureEither<Map<String, dynamic>> toggleReaction(int postId) async {
    return await _api.post<Map<String, dynamic>>(
      zPostsReactEndpoint,
      data: {'post_id': postId},
    );
  }

  FutureEither<PaginatedResult<dynamic>> fetchComments(int postId, {int page = 1}) async {
    final result = await _api.post<Map<String, dynamic>>(
      zPostsCommentsListEndpoint,
      data: {'post_id': postId, 'page': page},
    );
    // Since we don't have CommentModel yet, we'll return dynamic for now
    return result.map((res) {
      final data = res['data'] as List<dynamic>? ?? [];
      return PaginatedResult<dynamic>(
        items: data,
        currentPage: (res['current_page'] as num?)?.toInt() ?? 1,
        lastPage: (res['last_page'] as num?)?.toInt() ?? 1,
        total: (res['total'] as num?)?.toInt() ?? data.length,
      );
    });
  }

  FutureEither<dynamic> storeComment(int postId, String content) async {
    final result = await _api.post<dynamic>(
      zPostsCommentsStoreEndpoint,
      data: {'post_id': postId, 'content': content},
    );
    return result;
  }

  PaginatedResult<PostModel> _mapResult(Map<String, dynamic>? res) {
    if (res == null) {
      return const PaginatedResult(
          items: [], currentPage: 1, lastPage: 1, total: 0);
    }
    final data = res['data'] as List<dynamic>? ?? [];
    final meta = res['meta'] as Map<String, dynamic>? ?? {};
    return PaginatedResult<PostModel>(
      items: data
          .whereType<Map<String, dynamic>>()
          .map(PostModel.fromJson)
          .toList(),
      currentPage: (meta['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (meta['last_page'] as num?)?.toInt() ?? 1,
      total: (meta['total'] as num?)?.toInt() ?? data.length,
    );
  }
}
