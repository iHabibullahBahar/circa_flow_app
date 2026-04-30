import 'package:circa_flow_main/src/imports/imports.dart';
import '../../data/models/post_model.dart';
import '../../data/repositories/posts_repository.dart';

class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  final _repo = PostsRepository.instance;
  final _posts = <PostModel>[];
  bool _isLoading = true;
  bool _hasError = false;
  int _currentPage = 1;
  bool _hasNextPage = false;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200 &&
        _hasNextPage &&
        !_isLoading) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _posts.clear();
      _currentPage = 1;
    });
    final result = await _repo.fetchPosts(page: 1);
    result.fold(
      (_) => setState(() {
        _isLoading = false;
        _hasError = true;
      }),
      (page) => setState(() {
        _posts.addAll(page.items);
        _hasNextPage = page.hasNextPage;
        _isLoading = false;
      }),
    );
  }

  Future<void> _loadMore() async {
    setState(() => _isLoading = true);
    final result = await _repo.fetchPosts(page: _currentPage + 1);
    result.fold(
      (_) => setState(() => _isLoading = false),
      (page) => setState(() {
        _currentPage++;
        _posts.addAll(page.items);
        _hasNextPage = page.hasNextPage;
        _isLoading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.contextTheme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Posts'),
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: _hasError
          ? _ErrorView(onRetry: _load)
          : _posts.isEmpty && !_isLoading
              ? const _EmptyView()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: cs.primary,
                  child: ListView.separated(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: _posts.length + (_isLoading ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      if (i >= _posts.length) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: cs.primary),
                          ),
                        );
                      }
                      return _PostCard(post: _posts[i]);
                    },
                  ),
                ),
    );
  }
}

// ── Post Card ────────────────────────────────────────────────────────────────

class _PostCard extends StatelessWidget {
  final PostModel post;
  const _PostCard({required this.post});

  /// The single redirect URL set in the admin panel (stored as links[0].url).
  String? get _redirectUrl =>
      post.links.isNotEmpty ? post.links.first.url : null;

  void _onTap() {
    final url = _redirectUrl;
    if (url == null || url.isEmpty) return;
    Get.toNamed<void>(
      AppRoutes.webview,
      arguments: WebViewArgs(url: url, title: post.title),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.contextTheme.colorScheme;
    final tt = context.contextTheme.textTheme;
    final hasLink = _redirectUrl != null && _redirectUrl!.isNotEmpty;

    return GestureDetector(
      onTap: hasLink ? _onTap : null,
      child: Card(
        elevation: 0,
        color: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: hasLink ? cs.primary.withValues(alpha: 0.3) : cs.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.coverImage != null)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: AppCachedImage(
                  imageUrl: post.coverImage!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          post.title,
                          style: tt.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasLink) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.open_in_new_rounded,
                            size: 16, color: cs.primary),
                      ],
                    ],
                  ),
                  if (post.body != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      post.body!,
                      style: tt.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (post.publishedAt != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded,
                            size: 12, color: cs.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(post.publishedAt!),
                          style: tt.labelSmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}

// ── Empty & Error states ─────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override
  Widget build(BuildContext context) {
    final cs = context.contextTheme.colorScheme;
    final tt = context.contextTheme.textTheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article_outlined, size: 56, color: cs.outlineVariant),
          const SizedBox(height: 16),
          Text('No posts yet',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});
  @override
  Widget build(BuildContext context) {
    final cs = context.contextTheme.colorScheme;
    final tt = context.contextTheme.textTheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded, size: 56, color: cs.error),
          const SizedBox(height: 16),
          Text('Could not load posts',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 16),
          FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
