import 'package:circa_flow_main/src/imports/imports.dart';
import '../../data/models/post_model.dart';
import '../../data/repositories/posts_repository.dart';

class PostsController extends GetxController {
  final _repo = PostsRepository.instance;
  
  final posts = <PostModel>[].obs;
  final isLoading = false.obs;
  final hasError = false.obs;
  final hasNextPage = false.obs;
  int _currentPage = 1;

  @override
  void onInit() {
    super.onInit();
    refreshData();
  }

  Future<void> refreshData() async {
    if (isLoading.value) return;
    
    // Only show loading UI if list is currently empty
    final isSilent = posts.isNotEmpty;
    if (!isSilent) {
      isLoading.value = true;
    }
    hasError.value = false;
    _currentPage = 1;

    final result = await _repo.fetchPosts(page: 1);
    result.fold(
      (_) {
        if (!isSilent) {
          isLoading.value = false;
          hasError.value = true;
        }
      },
      (page) {
        posts.assignAll(page.items);
        hasNextPage.value = page.hasNextPage;
        isLoading.value = false;
      },
    );
  }

  Future<void> loadMore() async {
    if (isLoading.value || !hasNextPage.value) return;

    isLoading.value = true;
    final result = await _repo.fetchPosts(page: _currentPage + 1);
    result.fold(
      (_) => isLoading.value = false,
      (page) {
        _currentPage++;
        posts.addAll(page.items);
        hasNextPage.value = page.hasNextPage;
        isLoading.value = false;
      },
    );
  }

  Future<void> toggleReaction(PostModel post) async {
    final index = posts.indexOf(post);
    if (index == -1) return;

    // Optimistic UI update
    final wasLiked = post.isLiked;
    final updatedPost = post.copyWith(
      isLiked: !wasLiked,
      reactionCount: wasLiked ? post.reactionCount - 1 : post.reactionCount + 1,
    );
    posts[index] = updatedPost;

    final result = await _repo.toggleReaction(post.id);
    result.fold(
      (_) {
        // Rollback on error
        posts[index] = post;
      },
      (data) {
        // Sync with server response
        posts[index] = updatedPost.copyWith(
          isLiked: (data['is_liked'] as bool?) ?? !wasLiked,
          reactionCount:
              (data['reaction_count'] as num?)?.toInt() ?? updatedPost.reactionCount,
        );
      },
    );
  }
}
