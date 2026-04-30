import 'package:circa_flow_main/src/imports/imports.dart';
import 'package:circa_flow_main/src/config/config_controller.dart';
import 'package:circa_flow_main/src/features/home/presentation/screens/dashboard_screen.dart';
import 'package:circa_flow_main/src/features/posts/presentation/screens/posts_screen.dart';
import 'package:circa_flow_main/src/features/events/presentation/screens/events_screen.dart';
import 'package:circa_flow_main/src/features/documents/presentation/screens/documents_screen.dart';
import 'package:circa_flow_main/src/features/home/presentation/screens/more_screen.dart';
import 'package:circa_flow_main/src/features/posts/presentation/providers/posts_controller.dart' as import_posts;
import 'package:circa_flow_main/src/features/events/presentation/providers/events_controller.dart' as import_events;
import 'package:circa_flow_main/src/features/documents/presentation/providers/documents_controller.dart' as import_docs;
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

    // Events
    if (configCtrl.isModuleEnabled('events')) {
      items.add(TabItem(
        label: 'Events',
        icon: Icons.event_outlined,
        selectedIcon: Icons.event_rounded,
        screen: const EventsScreen(),
      ));
    }

    // Documents
    if (configCtrl.isModuleEnabled('documents')) {
      items.add(TabItem(
        label: 'Documents',
        icon: Icons.folder_outlined,
        selectedIcon: Icons.folder_rounded,
        screen: const DocumentsScreen(),
      ));
    }

    // More
    items.add(TabItem(
      label: 'More',
      icon: Icons.menu_rounded,
      selectedIcon: Icons.menu_rounded,
      screen: const MoreScreen(),
    ));

    tabs = items;
  }

  void changeTab(int index) {
    if (index == _currentIndex.value) {
      _triggerRefresh(tabs[index].label);
    }
    _currentIndex.value = index;
    _triggerRefresh(tabs[index].label);
  }

  void changeTabByLabel(String label) {
    final index = tabs.indexWhere((t) => t.label.toLowerCase() == label.toLowerCase());
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
        case 'documents':
          if (Get.isRegistered<import_docs.DocumentsController>()) {
            Get.find<import_docs.DocumentsController>().refreshData();
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

  const TabItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.screen,
  });
}
