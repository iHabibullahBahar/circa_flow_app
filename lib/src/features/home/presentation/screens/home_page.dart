import 'package:circa_flow_main/src/imports/imports.dart';
import 'package:circa_flow_main/src/config/config_controller.dart';
import 'package:circa_flow_main/src/features/posts/presentation/screens/posts_screen.dart';
import 'package:circa_flow_main/src/features/events/presentation/screens/events_screen.dart';
import 'package:circa_flow_main/src/features/documents/presentation/screens/documents_screen.dart';
import 'package:circa_flow_main/src/features/posts/presentation/providers/posts_controller.dart' as import_posts;
import 'package:circa_flow_main/src/features/events/presentation/providers/events_controller.dart' as import_events;
import 'package:circa_flow_main/src/features/documents/presentation/providers/documents_controller.dart' as import_docs;
import 'package:circa_flow_main/src/features/home/presentation/screens/more_screen.dart';

/// Module-aware home shell. Reads enabled modules from ConfigController and
/// only shows tabs for modules that are enabled. The "More" tab is always shown.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final configCtrl = Get.find<ConfigController>();
    final cs = context.contextTheme.colorScheme;

    return Obx(() {
      final tabs = _buildTabs(configCtrl);

      // Clamp index in case module count changes
      final safeIndex = _currentIndex.clamp(0, tabs.length - 1);

      return Scaffold(
        body: IndexedStack(
          index: safeIndex,
          children: tabs.map((t) => t.screen).toList(),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: safeIndex,
          onDestinationSelected: (i) {
            setState(() => _currentIndex = i);

            // Trigger refresh on selection (handles both switch and double-tap)
            final targetTab = tabs[i];
            _triggerRefresh(targetTab.label);
          },
          backgroundColor: cs.surface,
          indicatorColor: cs.primaryContainer,
          destinations: tabs
              .map((t) => NavigationDestination(
                    icon: Icon(t.icon),
                    selectedIcon: Icon(t.selectedIcon, color: cs.primary),
                    label: t.label,
                  ))
              .toList(),
        ),
      );
    });
  }

  void _triggerRefresh(String label) {
    try {
      switch (label.toLowerCase()) {
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

  List<_TabItem> _buildTabs(ConfigController ctrl) {
    final tabs = <_TabItem>[];

    // Posts tab is ALWAYS present (mandatory)
    tabs.add(_TabItem(
      label: 'Posts',
      icon: Icons.article_outlined,
      selectedIcon: Icons.article_rounded,
      screen: const PostsScreen(),
    ));

    if (ctrl.isModuleEnabled('events')) {
      tabs.add(_TabItem(
        label: 'Events',
        icon: Icons.event_outlined,
        selectedIcon: Icons.event_rounded,
        screen: const EventsScreen(),
      ));
    }

    if (ctrl.isModuleEnabled('documents')) {
      tabs.add(_TabItem(
        label: 'Documents',
        icon: Icons.folder_outlined,
        selectedIcon: Icons.folder_rounded,
        screen: const DocumentsScreen(),
      ));
    }

    // "More" tab is ALWAYS present
    tabs.add(_TabItem(
      label: 'More',
      icon: Icons.more_horiz_rounded,
      selectedIcon: Icons.more_horiz_rounded,
      screen: const MoreScreen(),
    ));

    return tabs;
  }
}

class _TabItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget screen;

  const _TabItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.screen,
  });
}
