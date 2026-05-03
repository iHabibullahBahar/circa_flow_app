import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:circa_flow_main/src/config/config_controller.dart';
import 'package:circa_flow_main/src/imports/imports.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:circa_flow_main/src/features/communities/presentation/controllers/community_controller.dart';

/// Handles all incoming deep links from two sources:
///   1. Universal Links / App Links — user taps a URL on app.circaflow.co.uk
///   2. OneSignal push notifications — notification payload contains a `deep_link` key
///
/// URL format: https://app.circaflow.co.uk/o/{org_slug}/{section}/{id}
///
/// Examples:
///   https://app.circaflow.co.uk/o/circa-flow/posts/42   → PostDetailScreen
///   https://app.circaflow.co.uk/o/circa-flow/events/7   → EventDetailScreen
///   https://app.circaflow.co.uk/o/circa-flow/documents/3 → DocumentDetailScreen
///
/// Adding new deep link routes in the future is a one-liner in [_routeBySegments].
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  static const _host = 'app.circaflow.co.uk';

  void init() {
    // 1. Handle links while the app is in the foreground or background
    _sub = _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (Object e) {
        AppLogger.error('DeepLinkService stream error: $e');
      },
    );

    // 2. Handle the cold-start link (app launched from terminated state by tapping a URL)
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        AppLogger.info('DeepLinkService cold-start link: $uri');
        _handleUri(uri);
      }
    }).catchError((Object e) {
      AppLogger.error('DeepLinkService cold-start error: $e');
    });

    // 3. Handle OneSignal notification taps that carry a deep_link in the data payload
    OneSignal.Notifications.addClickListener((event) {
      final deepLinkUrl =
          event.notification.additionalData?['deep_link'] as String?;
      if (deepLinkUrl != null && deepLinkUrl.isNotEmpty) {
        AppLogger.info('DeepLinkService from notification: $deepLinkUrl');
        final uri = Uri.tryParse(deepLinkUrl);
        if (uri != null) _handleUri(uri);
      }
    });
  }

  void dispose() {
    _sub?.cancel();
  }

  void _handleUri(Uri uri) {
    AppLogger.info('DeepLinkService handling URI: $uri');

    // Only handle links from our domain
    if (uri.host != _host) {
      AppLogger.warning('DeepLinkService: ignored foreign host ${uri.host}');
      return;
    }

    // Validate path structure: /o/{org_slug}/...
    final segments = uri.pathSegments;
    // segments[0] == 'o', segments[1] == org_slug
    if (segments.length < 2 || segments[0] != 'o') {
      _goHome();
      return;
    }

    // Validate org slug — ensures cross-tenant links are silently ignored
    final configCtrl = Get.find<ConfigController>();
    final currentSlug = configCtrl.config.value.organization.slug;
    final linkSlug = segments[1];
    if (linkSlug != currentSlug) {
      AppLogger.warning(
        'DeepLinkService: org slug mismatch (link=$linkSlug, current=$currentSlug)',
      );
      _goHome();
      return;
    }

    // Dispatch to the correct screen based on section + id
    _routeBySegments(segments.skip(2).toList());
  }

  /// Routes based on path segments after /o/{slug}/
  ///
  /// Add new features here as a simple case — no native code changes needed.
  void _routeBySegments(List<String> segments) {
    if (segments.length < 2) {
      _goHome();
      return;
    }

    final section = segments[0];
    final identifier = segments[1];

    if (section == 'communities') {
      // Communities use string slugs instead of numeric IDs
      Get.toNamed<void>(AppRoutes.communities);
      // Wait for binding to initialize, then lookup
      Future.delayed(const Duration(milliseconds: 500), () {
        if (Get.isRegistered<CommunityController>()) {
          Get.find<CommunityController>().lookupAndJoinCode(identifier);
        }
      });
      return;
    }

    // Other sections use numeric IDs
    final id = int.tryParse(identifier);

    if (id == null) {
      _goHome();
      return;
    }

    switch (section) {
      case 'posts':
        Get.toNamed<void>(AppRoutes.postDetail, arguments: {'id': id});
      case 'events':
        Get.toNamed<void>(AppRoutes.eventDetail, arguments: {'id': id});
      case 'documents':
        Get.toNamed<void>(AppRoutes.documentDetail, arguments: {'id': id});
      default:
        AppLogger.warning('DeepLinkService: unknown section "$section"');
        _goHome();
    }
  }

  void _goHome() {
    if (Get.currentRoute != AppRoutes.home) {
      Get.offAllNamed<void>(AppRoutes.home);
    }
  }
}
