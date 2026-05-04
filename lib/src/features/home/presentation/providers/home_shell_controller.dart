import 'package:circa_flow_main/src/imports/imports.dart';
import 'package:circa_flow_main/src/features/auth/presentation/providers/session_controller.dart';
import 'package:circa_flow_main/src/config/config_controller.dart';
import 'package:circa_flow_main/src/features/home/presentation/screens/dashboard_screen.dart';
import 'package:circa_flow_main/src/features/posts/presentation/screens/posts_screen.dart';
import 'package:circa_flow_main/src/features/events/presentation/screens/events_screen.dart';
import 'package:circa_flow_main/src/features/home/presentation/screens/more_screen.dart';
import 'package:circa_flow_main/src/features/messaging/presentation/screens/inbox_screen.dart';
import 'package:circa_flow_main/src/features/messaging/presentation/providers/inbox_controller.dart';
import 'package:circa_flow_main/src/features/messaging/data/repositories/inbox_repository.dart';
import 'package:circa_flow_main/src/features/posts/presentation/providers/posts_controller.dart' as import_posts;
import 'package:circa_flow_main/src/features/events/presentation/providers/events_controller.dart' as import_events;
import 'package:circa_flow_main/src/features/home/presentation/providers/dashboard_controller.dart';

class HomeShellController extends GetxController {
  final _currentIndex = 0.obs;
  int get currentIndex => _currentIndex.value;

  late final List<TabItem> tabs;

  @override
  void onInit() {
    super.onInit();
    _buildTabs();
  }

  void _buildTabs() {
    final configCtrl = Get.find<ConfigController>();
    final items = <TabItem>[];

    // ── Always visible ─────────────────────────────────────────────────────────

    // Home (Dashboard)
    items.add(TabItem(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      screen: const DashboardScreen(),
    ));

    // Posts
    items.add(TabItem(
      label: 'Posts',
      icon: Icons.article_outlined,
      selectedIcon: Icons.article_rounded,
      screen: const PostsScreen(),
    ));

    // ── Module-gated tabs ──────────────────────────────────────────────────────

    // Events
    if (configCtrl.isModuleEnabled('events')) {
      items.add(TabItem(
        label: 'Events',
        icon: Icons.event_outlined,
        selectedIcon: Icons.event_rounded,
        screen: const EventsScreen(),
      ));
    }

    // Messaging — shows in nav bar with unread badge when module is enabled.
    // Documents is moved to the More screen so messaging can sit in the bar.
    if (configCtrl.isModuleEnabled('messaging')) {
      // Register InboxController eagerly here because InboxScreen lives in
      // an IndexedStack (built immediately), not via route navigation.
      // InboxBinding would only run on Get.toNamed(AppRoutes.inbox) which
      // no longer happens for the tab variant.
      if (!Get.isRegistered<InboxController>(tag: 'inbox_controller')) {
        Get.put<InboxRepository>(InboxRepository(), permanent: true);
        Get.put<InboxController>(
          InboxController(repository: Get.find<InboxRepository>()),
          tag: 'inbox_controller',
          permanent: true,
        );
      }

      items.add(TabItem(
        label: 'Messages',
        icon: Icons.chat_bubble_outline_rounded,
        selectedIcon: Icons.chat_bubble_rounded,
        screen: const InboxScreen(),
        badgeBuilder: _buildMessagesBadge,
      ));
    }

    // ── Always visible ─────────────────────────────────────────────────────────

    // More (Documents, Communities, Links, Account, etc.)
    items.add(TabItem(
      label: 'More',
      icon: Icons.menu_rounded,
      selectedIcon: Icons.menu_rounded,
      screen: const MoreScreen(),
    ));

    tabs = items;
  }

  /// Builds the unread messages badge widget for the Messages tab.
  /// Returns null (no badge) when count is zero.
  Widget? _buildMessagesBadge() {
    if (!Get.isRegistered<InboxController>(tag: 'inbox_controller')) return null;
    if (!Get.find<SessionController>().isAuthenticated) return null;

    final inbox = Get.find<InboxController>(tag: 'inbox_controller');
    final count = inbox.sortedInbox.fold(0, (sum, c) => sum + c.unreadCount);
    if (count == 0) return null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(10),
      ),
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          height: 1.3,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  void changeTab(int index) {
    if (index == _currentIndex.value) {
      _triggerRefresh(tabs[index].label);
    }
    _currentIndex.value = index;
    _triggerRefresh(tabs[index].label);
  }

  void changeTabByLabel(String label) {
    final index = tabs.indexWhere(
        (t) => t.label.toLowerCase() == label.toLowerCase());
    if (index != -1) {
      _currentIndex.value = index;
      _triggerRefresh(tabs[index].label);
    }
  }

  void _triggerRefresh(String label) {
    try {
      switch (label.toLowerCase()) {
        case 'home':
          if (Get.isRegistered<DashboardController>()) {
            Get.find<DashboardController>().refreshData();
          }
          break;
        case 'posts':
          if (Get.isRegistered<import_posts.PostsController>()) {
            Get.find<import_posts.PostsController>().refreshData();
          }
          break;
        case 'events':
          if (Get.isRegistered<import_events.EventsController>()) {
            Get.find<import_events.EventsController>().refreshData();
          }
          break;
        case 'messages':
          if (Get.isRegistered<InboxController>(tag: 'inbox_controller') &&
              Get.find<SessionController>().isAuthenticated) {
            Get.find<InboxController>(tag: 'inbox_controller').refresh();
          }
          break;
      }
    } catch (e) {
      debugPrint('Error triggering refresh for $label: $e');
    }
  }
}

class TabItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget screen;

  /// Optional builder that returns a badge widget to overlay on the tab icon.
  /// If null or returns null, no badge is shown.
  final Widget? Function()? badgeBuilder;

  const TabItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.screen,
    this.badgeBuilder,
  });
}
