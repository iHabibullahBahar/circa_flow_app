import 'package:circa_flow_main/src/imports/imports.dart';
import '../../data/models/comment_model.dart';
import '../../data/repositories/posts_repository.dart';

class CommentsController extends GetxController {
  final int postId;
  CommentsController({required this.postId});

  final _repo = PostsRepository.instance;
  
  final comments = <CommentModel>[].obs;
  final totalComments = 0.obs;
  final isLoading = false.obs;
  final isPosting = false.obs;
  final hasError = false.obs;
  
  int _currentPage = 1;
  final hasNextPage = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchComments();
  }

  Future<void> fetchComments({bool refresh = true}) async {
    if (isLoading.value) return;
    
    if (refresh) {
      _currentPage = 1;
      isLoading.value = true;
    }
    
    hasError.value = false;
    
    final result = await _repo.fetchComments(postId, page: _currentPage);
    
    result.fold(
      (_) {
        isLoading.value = false;
        hasError.value = true;
      },
      (page) {
        final newItems = page.items.map((e) => CommentModel.fromJson(e as Map<String, dynamic>)).toList();
        if (refresh) {
          comments.assignAll(newItems);
        } else {
          comments.addAll(newItems);
        }
        totalComments.value = page.total;
        hasNextPage.value = page.hasNextPage;
        isLoading.value = false;
      },
    );
  }

  Future<void> loadMore() async {
    if (isLoading.value || !hasNextPage.value) return;
    _currentPage++;
    fetchComments(refresh: false);
  }

  Future<bool> postComment(String content) async {
    if (content.trim().isEmpty || isPosting.value) return false;
    
    isPosting.value = true;
    final result = await _repo.storeComment(postId, content);
    
    return result.fold(
      (error) {
        isPosting.value = false;
        AppToast.error(error.message);
        return false;
      },
      (data) {
        isPosting.value = false;
        final newComment = CommentModel.fromJson(data as Map<String, dynamic>);
        comments.insert(0, newComment);
        return true;
      },
    );
  }

  // Basic implementation for replies - in a real app might need a sub-controller per comment
  // but for simplicity we'll handle it here for now or just fetch when needed.
  Future<List<CommentModel>> fetchReplies(int commentId) async {
    // This uses the endpoint we defined: zCommentsRepliesListEndpoint
    final _api = ApiService.instance;
    final result = await _api.post<Map<String, dynamic>>(
      '/comments/replies/list',
      data: {'comment_id': commentId},
    );
    
    return result.fold(
      (_) => [],
      (res) {
        final List<dynamic> data = res['data'] ?? [];
        return data.map((e) => CommentModel.fromJson(e as Map<String, dynamic>)).toList();
      },
    );
  }

  Future<CommentModel?> postReply(int commentId, String content) async {
    if (content.trim().isEmpty || isPosting.value) return null;
    
    isPosting.value = true;
    final _api = ApiService.instance;
    final result = await _api.post<Map<String, dynamic>>(
      '/comments/replies/store',
      data: {'comment_id': commentId, 'content': content},
    );
    
    isPosting.value = false;
    return result.fold(
      (error) {
        AppToast.error(error.message);
        return null;
      },
      (data) {
        return CommentModel.fromJson(data);
      },
    );
  }
}
