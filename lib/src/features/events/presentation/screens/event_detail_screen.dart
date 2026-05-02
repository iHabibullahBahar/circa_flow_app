import 'package:circa_flow_main/src/imports/imports.dart';
import '../../data/models/event_model.dart';
import '../providers/events_controller.dart';
import 'package:intl/intl.dart';

class EventDetailScreen extends GetView<EventsController> {
  const EventDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final EventModel initialEvent = Get.arguments;
    final cs = context.contextTheme.colorScheme;
    final tt = context.contextTheme.textTheme;

    return Obx(() {
      // Find the latest state of this event from the controller list if it exists
      final event = controller.events.firstWhere(
        (e) => e.id == initialEvent.id,
        orElse: () => initialEvent,
      );

      return Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(
          title: const Text('Event Details'),
          centerTitle: true,
          backgroundColor: cs.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Get.back<void>(),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header Image ---
              AppCachedImage(
                imageUrl: event.coverImage ?? '',
                height: 220.h,
                width: double.infinity,
                fit: BoxFit.cover,
              ),

              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: tt.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 22.sp,
                        letterSpacing: -0.8,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- Date & Time Card ---
                    _InfoCard(
                      icon: Icons.calendar_today_rounded,
                      iconColor: Colors.blue[600]!,
                      title: 'Date & Time',
                      value: _formatFullDate(event.startsAt),
                      subtitle: _getTimeRange(event),
                      action: Icon(Icons.notifications_active_rounded,
                          color: cs.primary, size: 22),
                    ),
                    const SizedBox(height: 12),

                    // --- Location Card ---
                    _InfoCard(
                      icon: event.type == 'online'
                          ? Icons.videocam_rounded
                          : Icons.location_on_rounded,
                      iconColor:
                          event.type == 'online' ? Colors.teal[600]! : Colors.green[600]!,
                      title: 'Location',
                      value:
                          event.isOnline ? 'Online' : (event.location ?? 'TBA'),
                      subtitle: event.isOnline ? (event.onlineUrl ?? 'External Link') : (event.location ?? 'Physical Address'),
                    ),
                    const SizedBox(height: 12),

                    // --- Attendees Card ---
                    if (event.registrationEnabled && event.spotsLeft != null)
                      _InfoCard(
                        icon: Icons.people_rounded,
                        iconColor: Colors.deepPurple[400]!,
                        title: 'Attendees',
                        value: '${event.spotsLeft} spots left',
                        subtitle: 'Pre-registration required',
                      ),

                    const SizedBox(height: 32),
                    Text(
                      'About this event',
                      style:
                          tt.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      event.description ??
                          'No description available for this event.',
                      style: tt.bodyLarge?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // --- Action Buttons ---
                    if (event.registrationEnabled) ...[
                      AppButton(
                        label: event.isRegistered
                            ? 'Already Registered'
                            : 'Register for Event',
                        prefixIcon: Icon(
                            event.isRegistered
                                ? Icons.check_circle_rounded
                                : Icons.calendar_today_rounded,
                            color: event.isRegistered
                                ? cs.onSecondaryContainer
                                : cs.onPrimary),
                        isFullWidth: true,
                        variant: event.isRegistered
                            ? ButtonVariant.secondary
                            : ButtonVariant.primary,
                        onPressed: event.isRegistered
                            ? null
                            : () => controller.registerForEvent(event),
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (event.locationUrl != null &&
                        event.locationUrl!.isNotEmpty)
                      AppButton(
                        label: 'View on ${event.platform ?? 'PLATFORM'}',
                        prefixIcon: const Icon(Icons.link_rounded),
                        isFullWidth: true,
                        variant: ButtonVariant.outline,
                        onPressed: () async {
                          final uri = Uri.tryParse(event.locationUrl ?? '');
                          if (uri != null) {
                            await launchUrl(uri,
                                mode: LaunchMode.externalApplication);
                          }
                        },
                      ),

                    SizedBox(height: context.mediaQueryPadding.bottom + 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  String _formatFullDate(String? iso) {
    if (iso == null) return 'TBA';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('EEEE, d MMMM yyyy').format(dt);
    } catch (_) {
      return '';
    }
  }

  String _getTimeRange(EventModel event) {
    if (event.startsAt == null) return 'TBA';
    try {
      final start = DateTime.parse(event.startsAt!).toLocal();
      final startStr = _formatTime(start);
      if (event.endsAt != null) {
        final end = DateTime.parse(event.endsAt!).toLocal();
        return '$startStr - ${_formatTime(end)}';
      }
      return startStr;
    } catch (_) {
      return '';
    }
  }

  String _formatTime(DateTime dt) {
    return DateFormat('h:mm a').format(dt);
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String subtitle;
  final Widget? action;

  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.contextTheme.colorScheme;
    final tt = context.contextTheme.textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: tt.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: tt.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}
