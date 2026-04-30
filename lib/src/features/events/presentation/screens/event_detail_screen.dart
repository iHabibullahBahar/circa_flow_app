import 'package:circa_flow_main/src/imports/imports.dart';
import '../../data/models/event_model.dart';

class EventDetailScreen extends StatelessWidget {
  const EventDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final EventModel event = Get.arguments;
    final cs = context.contextTheme.colorScheme;
    final tt = context.contextTheme.textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        slivers: [
          // --- Header with Image ---
          SliverAppBar(
            expandedHeight: 300.h,
            pinned: true,
            backgroundColor: cs.surface,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black26,
                child: const BackButton(color: Colors.white),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  AppCachedImage(
                    imageUrl: event.coverImage ?? '',
                    fit: BoxFit.cover,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black26, Colors.transparent, Colors.black54],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- Content ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Date Badge Row ---
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _getDay(event.startsAt),
                              style: tt.headlineSmall?.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              _getMon(event.startsAt).toUpperCase(),
                              style: tt.labelSmall?.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              style: tt.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                fontSize: 22.sp,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- Info Row ---
                  _InfoItem(
                    icon: Icons.schedule_rounded,
                    label: 'Date & Time',
                    value: event.formattedDate,
                    color: cs.primary,
                  ),
                  const SizedBox(height: 16),
                  _InfoItem(
                    icon: Icons.location_on_rounded,
                    label: 'Location',
                    value: event.location ?? 'TBA',
                    color: Colors.redAccent,
                  ),
                  if (event.isOnline) ...[
                    const SizedBox(height: 16),
                    _InfoItem(
                      icon: Icons.videocam_rounded,
                      label: 'Meeting Type',
                      value: 'Online Event',
                      color: Colors.blueAccent,
                    ),
                  ],

                  const SizedBox(height: 32),
                  Text(
                    'About Event',
                    style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    event.description ?? 'No description available for this event.',
                    style: tt.bodyLarge?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.6,
                    ),
                  ),
                  
                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomAction(context, event),
    );
  }

  Widget? _buildBottomAction(BuildContext context, EventModel event) {
    final url = event.locationUrl;
    if (url == null || url.isEmpty) return null;

    final cs = context.contextTheme.colorScheme;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + context.mediaQueryPadding.bottom),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5))),
      ),
      child: AppButton(
        label: event.isOnline ? 'Join Event' : 'Visit Website',
        isFullWidth: true,
        onPressed: () => Get.toNamed<void>(
          AppRoutes.webview,
          arguments: WebViewArgs(url: url, title: event.title),
        ),
      ),
    );
  }

  String _getDay(String? date) {
    if (date == null) return '';
    try {
      return DateTime.parse(date).day.toString();
    } catch (_) {
      return '';
    }
  }

  String _getMon(String? date) {
    if (date == null) return '';
    try {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return months[DateTime.parse(date).month - 1];
    } catch (_) {
      return '';
    }
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.contextTheme.colorScheme;
    final tt = context.contextTheme.textTheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              Text(
                value,
                style: tt.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
