import 'package:circa_flow_main/src/imports/imports.dart';
import '../providers/home_shell_controller.dart';

/// Module-aware home shell. Reads enabled modules from ConfigController and
/// only shows tabs for modules that are enabled. The "Home" (Dashboard) and
/// "More" tabs are always shown.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeShellController());
    final cs = context.contextTheme.colorScheme;

    return Obx(() {
      final tabs = controller.tabs;
      final safeIndex = controller.currentIndex.clamp(0, tabs.length - 1);

      return Scaffold(
        body: IndexedStack(
          index: safeIndex,
          children: tabs.map((t) => t.screen).toList(),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: cs.outlineVariant.withValues(alpha: 0.5),
                width: 0.5,
              ),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: safeIndex,
            onTap: controller.changeTab,
            backgroundColor: cs.surface,
            selectedItemColor: cs.primary,
            unselectedItemColor: cs.onSurfaceVariant,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            selectedFontSize: 11,
            unselectedFontSize: 11,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
            items: tabs.map((t) {
              // Build icon with optional badge overlay.
              // No inner Obx needed — the outer Obx on the Scaffold tracks
              // every observable read here (including inbox.sortedInbox via
              // badgeBuilder), so the full nav bar rebuilds on any change.
              Widget buildIcon(IconData iconData) {
                final badge = t.badgeBuilder?.call();
                if (badge == null) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Icon(iconData, size: 24),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(iconData, size: 24),
                      Positioned(
                        top: -4,
                        right: -8,
                        child: badge,
                      ),
                    ],
                  ),
                );
              }

              return BottomNavigationBarItem(
                icon: buildIcon(t.icon),
                activeIcon: buildIcon(t.selectedIcon),
                label: t.label,
              );
            }).toList(),
          ),
        ),
      );
    });
  }
}
