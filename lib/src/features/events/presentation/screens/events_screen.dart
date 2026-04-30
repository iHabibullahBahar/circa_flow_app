import 'package:circa_flow_main/src/imports/imports.dart';
import '../../data/models/event_model.dart';
import '../../data/repositories/events_repository.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final _repo = EventsRepository.instance;
  final _events = <EventModel>[];
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
      _events.clear();
      _currentPage = 1;
    });
    final result = await _repo.fetchEvents(page: 1);
    result.fold(
      (_) => setState(() {
        _isLoading = false;
        _hasError = true;
      }),
      (page) => setState(() {
        _events.addAll(page.items);
        _hasNextPage = page.hasNextPage;
        _isLoading = false;
      }),
    );
  }

  Future<void> _loadMore() async {
    setState(() => _isLoading = true);
    final result = await _repo.fetchEvents(page: _currentPage + 1);
    result.fold(
      (_) => setState(() => _isLoading = false),
      (page) => setState(() {
        _currentPage++;
        _events.addAll(page.items);
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
        title: const Text('Events'),
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: _hasError
          ? _ErrorView(onRetry: _load)
          : _events.isEmpty && !_isLoading
              ? const _EmptyView()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: cs.primary,
                  child: ListView.separated(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: _events.length + (_isLoading ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      if (i >= _events.length) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: cs.primary),
                          ),
                        );
                      }
                      return _EventCard(event: _events[i]);
                    },
                  ),
                ),
    );
  }
}

// ── Event Card ───────────────────────────────────────────────────────────────

class _EventCard extends StatelessWidget {
  final EventModel event;
  const _EventCard({required this.event});

  /// The redirect URL is stored in location_url (labelled "Redirect URL" in
  /// the admin form). A non-empty value means the card is tappable.
  String? get _redirectUrl {
    final url = event.locationUrl;
    return (url != null && url.isNotEmpty) ? url : null;
  }

  void _onTap() {
    final url = _redirectUrl;
    if (url == null) return;
    Get.toNamed<void>(
      AppRoutes.webview,
      arguments: WebViewArgs(url: url, title: event.title),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.contextTheme.colorScheme;
    final tt = context.contextTheme.textTheme;
    final hasLink = _redirectUrl != null;

    return GestureDetector(
      onTap: hasLink ? _onTap : null,
      child: Card(
        elevation: 0,
        color: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: hasLink
                ? cs.primary.withValues(alpha: 0.3)
                : cs.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.coverImage != null)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: AppCachedImage(
                  imageUrl: event.coverImage!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date badge
                  if (event.startsAt != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_rounded,
                              size: 13, color: cs.onPrimaryContainer),
                          const SizedBox(width: 4),
                          Text(
                            event.formattedDate,
                            style: tt.labelSmall?.copyWith(
                              color: cs.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Title row with optional link icon
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
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

                  if (event.description != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      event.description!,
                      style: tt.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // Location row — only show when it's an actual place name,
                  // not the redirect URL that's stored in location_url
                  if (event.location != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          event.isOnline
                              ? Icons.videocam_outlined
                              : Icons.place_outlined,
                          size: 14,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.isOnline ? 'Online event' : event.location!,
                            style: tt.labelSmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                            overflow: TextOverflow.ellipsis,
                          ),
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
          Icon(Icons.event_outlined, size: 56, color: cs.outlineVariant),
          const SizedBox(height: 16),
          Text('No events yet',
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
          Text('Could not load events',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 16),
          FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
