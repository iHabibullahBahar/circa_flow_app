// Typed models for the /api/v1/config response.
// All fields are nullable to be resilient against backend evolution.

class OrganizationConfig {
  final int id;
  final String name;
  final String slug;
  final String? timezone;

  const OrganizationConfig({
    required this.id,
    required this.name,
    required this.slug,
    this.timezone,
  });

  factory OrganizationConfig.fromJson(Map<String, dynamic> json) {
    return OrganizationConfig(
      id: (json['id'] as num).toInt(),
      name: (json['name'] as String?) ?? 'App',
      slug: (json['slug'] as String?) ?? '',
      timezone: json['timezone'] as String?,
    );
  }

  /// Fallback when no config has been fetched yet.
  factory OrganizationConfig.fallback() =>
      const OrganizationConfig(id: 0, name: 'App', slug: '');
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

  factory ModulesConfig.fromJson(Map<String, dynamic> json) {
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
      id: (json['id'] as num).toInt(),
      title: (json['title'] as String?) ?? '',
      url: (json['url'] as String?) ?? '',
      icon: json['icon'] as String?,
      type: (json['type'] as String?) ?? 'webview',
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }
}

/// The root config model returned by POST /api/v1/config.
class AppConfigModel {
  final OrganizationConfig organization;
  final BrandingConfig branding;
  final ModulesConfig modules;
  final List<CustomLink> customLinks;

  const AppConfigModel({
    required this.organization,
    required this.branding,
    required this.modules,
    required this.customLinks,
  });

  factory AppConfigModel.fromJson(Map<String, dynamic> json) {
    // Backend wraps the payload in a "data" envelope.
    final data = (json['data'] as Map<String, dynamic>?) ?? json;

    final linksJson = data['custom_links'] as List<dynamic>? ?? [];

    return AppConfigModel(
      organization: OrganizationConfig.fromJson(
          (data['organization'] as Map<String, dynamic>?) ?? {}),
      branding: BrandingConfig.fromJson(
          (data['branding'] as Map<String, dynamic>?) ?? {}),
      modules: ModulesConfig.fromJson(
          (data['modules'] as Map<String, dynamic>?) ?? {}),
      customLinks: linksJson
          .map((e) => CustomLink.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order)),
    );
  }

  /// Used as a safe default before config is loaded.
  factory AppConfigModel.fallback() => AppConfigModel(
        organization: OrganizationConfig.fallback(),
        branding: BrandingConfig.fallback(),
        modules: ModulesConfig.fallback(),
        customLinks: const [],
      );

  Map<String, dynamic> toJson() => {
        'data': {
          'organization': {
            'id': organization.id,
            'name': organization.name,
            'slug': organization.slug,
            'timezone': organization.timezone,
          },
          'branding': {
            'primary_color': branding.primaryColor,
            'logo_url': branding.logoUrl,
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
        }
      };
}
