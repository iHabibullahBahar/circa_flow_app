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
