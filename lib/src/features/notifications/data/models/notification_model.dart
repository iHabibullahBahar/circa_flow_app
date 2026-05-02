class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String? deepLink;
  final Map<String, dynamic> extra;
  final DateTime createdAt;
  final DateTime? readAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.deepLink,
    required this.extra,
    required this.createdAt,
    this.readAt,
  });

  bool get isRead => readAt != null;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return NotificationModel(
      id: json['id'] as String,
      title: data['title'] as String? ?? 'Notification',
      body: data['body'] as String? ?? '',
      deepLink: data['deep_link'] as String?,
      extra: data['extra'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at'] as String) : null,
    );
  }
}
