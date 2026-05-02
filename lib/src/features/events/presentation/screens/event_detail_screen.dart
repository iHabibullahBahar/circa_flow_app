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
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Gap(24),

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
                    const Gap(12),

                    // --- Location Card ---
                    _InfoCard(
                      icon: event.type == 'online'
                          ? Icons.videocam_rounded
                          : Icons.location_on_rounded,
                      iconColor: event.type == 'online'
                          ? Colors.teal[600]!
                          : Colors.green[600]!,
                      title: 'Location',
                      value:
                          event.isOnline ? 'Online' : (event.location ?? 'TBA'),
                      subtitle: event.isOnline
                          ? (event.onlineUrl ?? 'External Link')
                          : (event.location ?? 'Physical Address'),
                    ),
                    const Gap(12),

                    // --- Attendees Card ---
                    if (event.registrationEnabled &&
                        event.spotsLeft != null) ...[
                      _InfoCard(
                        icon: Icons.people_rounded,
                        iconColor: Colors.deepPurple[400]!,
                        title: 'Attendees',
                        value: '${event.spotsLeft} spots left',
                        subtitle: 'Pre-registration required',
                      ),
                      const Gap(32),
                    ],

                    Text(
                      'About this event',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const Gap(12),
                    Text(
                      event.description ??
                          'No description available for this event.',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.black54,
                        height: 1.5,
                      ),
                    ),

                    const Gap(40),

                    // --- Action Buttons ---
                    if (event.registrationEnabled) ...[
                      AppButton(
                        label: event.isRegistered
                            ? 'Cancel Registration'
                            : 'Register for Event',
                        prefixIcon: Icon(
                            event.isRegistered
                                ? Icons.cancel_outlined
                                : Icons.calendar_today_rounded,
                            color: event.isRegistered
                                ? Colors.red[700]
                                : cs.onPrimary),
                        isFullWidth: true,
                        variant: event.isRegistered
                            ? ButtonVariant.secondary
                            : ButtonVariant.primary,
                        onPressed: event.isRegistered
                            ? () => _showCancelDialog(context, event)
                            : () => controller.registerForEvent(event),
                      ),
                      const Gap(12),
                    ],

                    if (event.locationUrl != null &&
                        event.locationUrl!.isNotEmpty)
                      AppButton(
                        label: 'View on ${event.platform ?? 'Website'}',
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

  void _showCancelDialog(BuildContext context, EventModel event) {
    AppDialogs.showConfirm(
      title: 'Cancel Registration',
      description: 'Are you sure you want to cancel your registration for this event?',
      confirmLabel: 'Yes, Cancel',
      cancelLabel: 'No, Keep it',
      icon: Icons.cancel_outlined,
      iconColor: Colors.red[700],
      iconBgColor: Colors.red[50],
      confirmVariant: ButtonVariant.danger,
      onConfirm: () => controller.cancelRegistration(event),
    );
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
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.black38,
                  ),
                ),
                const Gap(2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.black38,
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
