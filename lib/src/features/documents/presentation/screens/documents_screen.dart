import 'package:circa_flow_main/src/imports/imports.dart';
import '../../data/models/document_model.dart';
import '../../data/repositories/documents_repository.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final _repo = DocumentsRepository.instance;
  final _docs = <DocumentModel>[];
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
      _docs.clear();
      _currentPage = 1;
    });
    final result = await _repo.fetchDocuments(page: 1);
    result.fold(
      (_) => setState(() {
        _isLoading = false;
        _hasError = true;
      }),
      (page) => setState(() {
        _docs.addAll(page.items);
        _hasNextPage = page.hasNextPage;
        _isLoading = false;
      }),
    );
  }

  Future<void> _loadMore() async {
    setState(() => _isLoading = true);
    final result = await _repo.fetchDocuments(page: _currentPage + 1);
    result.fold(
      (_) => setState(() => _isLoading = false),
      (page) => setState(() {
        _currentPage++;
        _docs.addAll(page.items);
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
        title: const Text('Documents'),
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: _hasError
          ? _ErrorView(onRetry: _load)
          : _docs.isEmpty && !_isLoading
              ? const _EmptyView()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: cs.primary,
                  child: ListView.separated(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: _docs.length + (_isLoading ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      if (i >= _docs.length) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: cs.primary),
                          ),
                        );
                      }
                      return _DocumentTile(doc: _docs[i]);
                    },
                  ),
                ),
    );
  }
}

// ── Document Tile ─────────────────────────────────────────────────────────────

class _DocumentTile extends StatelessWidget {
  final DocumentModel doc;
  const _DocumentTile({required this.doc});

  @override
  Widget build(BuildContext context) {
    final cs = context.contextTheme.colorScheme;
    final tt = context.contextTheme.textTheme;

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(doc.fileIcon, color: cs.onPrimaryContainer, size: 22),
        ),
        title: Text(
          doc.title,
          style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (doc.description != null)
              Text(
                doc.description!,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            Row(
              children: [
                if (doc.fileType != null) ...[
                  Text(
                    doc.fileType!.toUpperCase(),
                    style: tt.labelSmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (doc.fileSizeBytes != null)
                  Text(
                    doc.fileSizeFormatted,
                    style:
                        tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                const SizedBox(width: 8),
                Icon(Icons.download_outlined,
                    size: 12, color: cs.onSurfaceVariant),
                const SizedBox(width: 2),
                Text(
                  '${doc.downloadsCount}',
                  style:
                      tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
        trailing: doc.downloadUrl != null
            ? IconButton(
                icon: Icon(Icons.open_in_new_rounded,
                    color: cs.primary, size: 20),
                onPressed: () => Get.toNamed<void>(
                  AppRoutes.webview,
                  arguments: WebViewArgs(
                    url: doc.downloadUrl!,
                    title: doc.title,
                  ),
                ),
              )
            : null,
      ),
    );
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
          Icon(Icons.folder_outlined, size: 56, color: cs.outlineVariant),
          const SizedBox(height: 16),
          Text('No documents yet',
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
          Text('Could not load documents',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 16),
          FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
