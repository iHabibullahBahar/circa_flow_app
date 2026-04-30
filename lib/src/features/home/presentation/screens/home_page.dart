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
            items: tabs
                .map((t) => BottomNavigationBarItem(
                      icon: Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Icon(t.icon, size: 24),
                      ),
                      activeIcon: Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Icon(t.selectedIcon, size: 24),
                      ),
                      label: t.label,
                    ))
                .toList(),
          ),
        ),
      );
    });
  }
}
