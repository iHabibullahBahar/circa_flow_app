/// Data model for an Event, typed against EventResource from the backend.
import 'package:circa_flow_main/src/features/posts/data/models/post_model.dart'
    show PostLink;

class EventModel {
  final int id;
  final String title;
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
  final List<PostLink> links;

  const EventModel({
    required this.id,
    required this.title,
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
    this.links = const [],
  });

  factory EventModel.fromJson(Map<String, dynamic> j) => EventModel(
        id: (j['id'] as num).toInt(),
        title: (j['title'] as String?) ?? '',
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
        links: (j['links'] as List<dynamic>?)
                ?.whereType<Map<String, dynamic>>()
                .map(PostLink.fromJson)
                .toList() ??
            [],
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
