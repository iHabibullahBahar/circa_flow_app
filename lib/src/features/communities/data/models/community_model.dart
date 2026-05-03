class CommunityModel {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final String? coverImageUrl;
  final String type; // 'public', 'private'
  final String joinType; // 'open', 'approval', 'invite_only'
  final String visibility; // 'public', 'hidden'
  final bool isDefault;
  final bool isActive;
  final List<String> featureFlags;
  final int memberCount;
  final String? myRole; // 'owner', 'moderator', 'member', null
  final String? myStatus; // 'approved', 'pending', 'rejected', 'blocked', null

  const CommunityModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.coverImageUrl,
    required this.type,
    required this.joinType,
    required this.visibility,
    this.isDefault = false,
    this.isActive = true,
    this.featureFlags = const [],
    this.memberCount = 0,
    this.myRole,
    this.myStatus,
  });

  factory CommunityModel.fromJson(Map<String, dynamic> json) {
    return CommunityModel(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      type: json['type'] as String,
      joinType: json['join_type'] as String,
      visibility: json['visibility'] as String,
      isDefault: json['is_default'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      featureFlags: (json['feature_flags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      memberCount: json['member_count'] as int? ?? 0,
      myRole: json['my_role'] as String?,
      myStatus: json['my_status'] as String?,
    );
  }

  bool get isMember => myStatus == 'approved';
  bool get isPending => myStatus == 'pending';
  bool get isRejected => myStatus == 'rejected';
  bool get canRequestJoin =>
      !isMember &&
      !isPending &&
      myStatus != 'blocked' &&
      joinType != 'invite_only';
  bool get canJoinInstantly => canRequestJoin && joinType == 'open';
}
