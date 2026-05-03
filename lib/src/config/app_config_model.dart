// Typed models for the /api/v1/config response.
// All fields are nullable to be resilient against backend evolution.

class OrganizationConfig {
  final int id;
  final String name;
  final String slug;
  final String? timezone;
  final String? appStoreUrl;
  final String? playStoreUrl;

  const OrganizationConfig({
    required this.id,
    required this.name,
    required this.slug,
    this.timezone,
    this.appStoreUrl,
    this.playStoreUrl,
  });

  factory OrganizationConfig.fromJson(Map<String, dynamic> json) {
    return OrganizationConfig(
      id: (json['id'] as num).toInt(),
      name: (json['name'] as String?) ?? 'App',
      slug: (json['slug'] as String?) ?? '',
      timezone: json['timezone'] as String?,
      appStoreUrl: json['app_store_url'] as String?,
      playStoreUrl: json['play_store_url'] as String?,
    );
  }

  /// Fallback when no config has been fetched yet.
  factory OrganizationConfig.fallback() =>
      const OrganizationConfig(id: 0, name: 'App', slug: '');
}

class VersionConfig {
  final String minAppVersion;
  final int minBuildNumber;

  const VersionConfig({
    this.minAppVersion = '1.0.0',
    this.minBuildNumber = 1,
  });

  factory VersionConfig.fromJson(Map<String, dynamic> json) {
    return VersionConfig(
      minAppVersion: (json['min_app_version'] as String?) ?? '1.0.0',
      minBuildNumber: (json['min_build_number'] as num?)?.toInt() ?? 1,
    );
  }

  factory VersionConfig.fallback() => const VersionConfig();
}

class BrandingConfig {
  final String primaryColor;
  final String? logoUrl;

  const BrandingConfig({
    required this.primaryColor,
    this.logoUrl,
  });

  factory BrandingConfig.fromJson(Map<String, dynamic> json) {
    return BrandingConfig(
      primaryColor: (json['primary_color'] as String?) ?? '#6750A4',
      logoUrl: json['logo_url'] as String?,
    );
  }

  factory BrandingConfig.fallback() =>
      const BrandingConfig(primaryColor: '#6750A4');
}

class ModulesConfig {
  final bool posts;
  final bool events;
  final bool documents;
  final bool notifications;

  const ModulesConfig({
    this.posts = false,
    this.events = false,
    this.documents = false,
    this.notifications = false,
  });

  factory ModulesConfig.fromJson(dynamic json) {
    if (json is! Map) return ModulesConfig.fallback();
    bool flag(String key) => json[key] == true;
    return ModulesConfig(
      posts: flag('posts'),
      events: flag('events'),
      documents: flag('documents'),
      notifications: flag('notifications'),
    );
  }

  bool isEnabled(String key) {
    return switch (key) {
      'posts' => posts,
      'events' => events,
      'documents' => documents,
      'notifications' => notifications,
      _ => false,
    };
  }

  factory ModulesConfig.fallback() => const ModulesConfig();
}

class CustomLink {
  final int id;
  final String title;
  final String url;
  final String? icon;
  final String type;
  final int order;

  const CustomLink({
    required this.id,
    required this.title,
    required this.url,
    this.icon,
    this.type = 'webview',
    this.order = 0,
  });

  factory CustomLink.fromJson(Map<String, dynamic> json) {
    return CustomLink(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] as String?) ?? '',
      url: (json['url'] as String?) ?? '',
      icon: json['icon'] as String?,
      type: (json['type'] as String?) ?? 'webview',
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }
}

class BannerConfig {
  final int id;
  final String imageUrl;
  final String? title;
  final String? subtitle;
  final String actionType;
  final String? actionValue;

  const BannerConfig({
    required this.id,
    required this.imageUrl,
    this.title,
    this.subtitle,
    this.actionType = 'none',
    this.actionValue,
  });

  factory BannerConfig.fromJson(Map<String, dynamic> json) {
    return BannerConfig(
      id: (json['id'] as num?)?.toInt() ?? 0,
      imageUrl: (json['image_url'] as String?) ?? '',
      title: json['title'] as String?,
      subtitle: json['subtitle'] as String?,
      actionType: (json['action_type'] as String?) ?? 'none',
      actionValue: json['action_value'] as String?,
    );
  }
}

class OnboardingSlide {
  final String title;
  final String subtitle;

  const OnboardingSlide({
    required this.title,
    required this.subtitle,
  });

  factory OnboardingSlide.fromJson(Map<String, dynamic> json) {
    return OnboardingSlide(
      title: (json['title'] as String?) ?? '',
      subtitle: (json['subtitle'] as String?) ?? '',
    );
  }
}

/// The root config model returned by POST /api/v1/config.
class AppConfigModel {
  final OrganizationConfig organization;
  final BrandingConfig branding;
  final VersionConfig version;
  final ModulesConfig modules;
  final List<CustomLink> customLinks;
  final List<CustomLink> customButtons;
  final List<BannerConfig> banners;
  final List<OnboardingSlide> onboarding;
  final bool allowRegistration;
  final bool allowGuestAccess;
  final Map<String, List<String>> actionGuards;

  const AppConfigModel({
    required this.organization,
    required this.branding,
    required this.version,
    required this.modules,
    required this.customLinks,
    required this.customButtons,
    required this.banners,
    required this.onboarding,
    this.allowRegistration = false,
    this.allowGuestAccess = false,
    this.actionGuards = const {},
  });

  factory AppConfigModel.fromJson(Map<String, dynamic> json) {
    // Backend wraps the payload in a "data" envelope.
    final data = (json['data'] as Map<String, dynamic>?) ?? json;

    final rawLinks = data['custom_links'];
    final List<dynamic> linksJson = (rawLinks is List) ? rawLinks : [];

    final rawBtns = data['custom_buttons'];
    final List<dynamic> btnsJson = (rawBtns is List) ? rawBtns : [];

    return AppConfigModel(
      organization: OrganizationConfig.fromJson(
          (data['organization'] as Map<String, dynamic>?) ?? {}),
      branding: BrandingConfig.fromJson(
          (data['branding'] as Map<String, dynamic>?) ?? {}),
      version: VersionConfig.fromJson(
          (data['version'] as Map<String, dynamic>?) ?? {}),
      modules: ModulesConfig.fromJson(data['modules']),
      customLinks: linksJson
          .whereType<Map<String, dynamic>>()
          .map((e) => CustomLink.fromJson(e))
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order)),
      customButtons: btnsJson
          .whereType<Map<String, dynamic>>()
          .map((e) => CustomLink.fromJson(e))
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order)),
      banners: (data['banners'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map((e) => BannerConfig.fromJson(e))
              .toList() ??
          [],
      onboarding: (data['onboarding'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map((e) => OnboardingSlide.fromJson(e))
              .toList() ??
          const [],
      allowRegistration: data['allow_registration'] == true,
      allowGuestAccess: data['allow_guest_access'] == true,
      actionGuards: (data['action_guards'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, (value as List).cast<String>()),
          ) ??
          const {},
    );
  }

  /// Used as a safe default before config is loaded.
  factory AppConfigModel.fallback() => AppConfigModel(
        organization: OrganizationConfig.fallback(),
        branding: BrandingConfig.fallback(),
        version: VersionConfig.fallback(),
        modules: ModulesConfig.fallback(),
        customLinks: const [],
        customButtons: const [],
        banners: const [],
        onboarding: const [],
        allowRegistration: false,
        allowGuestAccess: false,
        actionGuards: const {},
      );

  Map<String, dynamic> toJson() => {
        'data': {
          'organization': {
            'id': organization.id,
            'name': organization.name,
            'slug': organization.slug,
            'timezone': organization.timezone,
            'app_store_url': organization.appStoreUrl,
            'play_store_url': organization.playStoreUrl,
          },
          'branding': {
            'primary_color': branding.primaryColor,
            'logo_url': branding.logoUrl,
          },
          'version': {
            'min_app_version': version.minAppVersion,
            'min_build_number': version.minBuildNumber,
          },
          'modules': {
            'posts': modules.posts,
            'events': modules.events,
            'documents': modules.documents,
            'notifications': modules.notifications,
          },
          'custom_links': customLinks.map((l) => {
                'id': l.id,
                'title': l.title,
                'url': l.url,
                'icon': l.icon,
                'type': l.type,
                'order': l.order,
              }).toList(),
          'custom_buttons': customButtons.map((l) => {
                'id': l.id,
                'title': l.title,
                'url': l.url,
                'icon': l.icon,
                'type': l.type,
                'order': l.order,
              }).toList(),
          'allow_registration': allowRegistration,
          'allow_guest_access': allowGuestAccess,
          'onboarding': onboarding
              .map((s) => {'title': s.title, 'subtitle': s.subtitle})
              .toList(),
          'action_guards': actionGuards,
        }
      };
}
