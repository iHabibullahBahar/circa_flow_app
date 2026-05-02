/// Data model for an Event, typed against EventResource from the backend.
import 'package:circa_flow_main/src/features/posts/data/models/post_model.dart'
    show PostLink;

class EventModel {
  final int id;
  final String title;
  final String type;
  final String? description;
  final String? coverImage;
  final String? location;
  final String? locationUrl;
  final String? startsAt;
  final String? endsAt;
  final bool isOnline;
  final String? onlineUrl;
  final String? organizer;
  final int? capacity;
  final String? timezone;
  final String? platform;
  final bool registrationEnabled;
  final bool isRegistered;
  final int? spotsLeft;
  final List<PostLink> links;
  final String redirectionTarget;

  const EventModel({
    required this.id,
    required this.title,
    this.type = 'physical',
    this.description,
    this.coverImage,
    this.location,
    this.locationUrl,
    this.startsAt,
    this.endsAt,
    this.isOnline = false,
    this.onlineUrl,
    this.organizer,
    this.capacity,
    this.timezone,
    this.platform,
    this.registrationEnabled = false,
    this.isRegistered = false,
    this.spotsLeft,
    this.links = const [],
    this.redirectionTarget = 'app',
  });

  factory EventModel.fromJson(Map<String, dynamic> j) => EventModel(
        id: (j['id'] as num).toInt(),
        title: (j['title'] as String?) ?? '',
        type: (j['type'] as String?) ?? 'physical',
        description: j['description'] as String?,
        coverImage: j['cover_image'] as String?,
        location: j['location'] as String?,
        locationUrl: j['location_url'] as String?,
        startsAt: j['starts_at'] as String?,
        endsAt: j['ends_at'] as String?,
        isOnline: (j['is_online'] as bool?) ?? false,
        onlineUrl: j['online_url'] as String?,
        organizer: j['organizer'] as String?,
        capacity: (j['capacity'] as num?)?.toInt(),
        timezone: j['timezone'] as String?,
        platform: j['platform'] as String?,
        registrationEnabled: (j['registration_enabled'] as bool?) ?? false,
        isRegistered: (j['is_registered'] as bool?) ?? false,
        spotsLeft: (j['spots_left'] as num?)?.toInt(),
        links: (j['links'] as List<dynamic>?)
                ?.whereType<Map<String, dynamic>>()
                .map(PostLink.fromJson)
                .toList() ??
            [],
        redirectionTarget: (j['redirection_target'] as String?) ?? 'app',
      );

  String get formattedDate {
    if (startsAt == null) return '';
    try {
      final dt = DateTime.parse(startsAt!).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}  '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return startsAt ?? '';
    }
  }
}
