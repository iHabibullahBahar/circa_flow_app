import 'package:circa_flow_main/src/imports/imports.dart';
import 'package:circa_flow_main/src/config/config_controller.dart';
import 'package:circa_flow_main/src/config/app_config_model.dart';
import 'package:circa_flow_main/src/features/auth/presentation/providers/session_controller.dart';
import 'package:circa_flow_main/src/shared/screens/webview_screen.dart';

/// "More" tab: shows account info, dynamic custom links from the backend,
/// and the logout button. All links open in the in-app WebView.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final configCtrl = Get.find<ConfigController>();
    final session = Get.find<SessionController>();
    final cs = context.contextTheme.colorScheme;
    final tt = context.contextTheme.textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          children: [
            // --- User Info ---
            Obx(() {
              final user = session.user.value;
              final isAuthenticated = session.isAuthenticated;
              final isGuest = !isAuthenticated;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: isGuest ? cs.surfaceVariant : cs.primaryContainer,
                      child: isGuest 
                        ? Icon(Icons.person_outline_rounded, color: cs.onSurfaceVariant)
                        : Text(
                            (user?.name?.isNotEmpty == true
                                    ? user!.name![0]
                                    : user?.email.isNotEmpty == true
                                        ? user!.email[0]
                                        : 'U') // 'U' for User as fallback
                                .toUpperCase(),
                            style: tt.titleMedium?.copyWith(
                              color: cs.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isGuest ? 'Guest' : (user?.name ?? 'Member'),
                            style: tt.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            isGuest 
                              ? 'Sign in to access more features' 
                              : (user?.email ?? ''),
                            style: tt.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),

            // --- Custom Links ---
            Obx(() {
              final links = configCtrl.customLinks;
              if (links.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Links',
                      style: tt.labelMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: Column(
                      children: links
                          .asMap()
                          .entries
                          .map((entry) => _buildLinkTile(
                                context,
                                entry.value,
                                showDivider:
                                    entry.key < links.length - 1,
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            }),

            // --- Auth Action ---
            Obx(() {
              final isGuest = !session.isAuthenticated;
              
              if (isGuest) {
                return Container(
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
                  ),
                  child: ListTile(
                    leading: Icon(Icons.login_rounded, color: cs.primary, size: 22),
                    title: Text(
                      'Sign In',
                      style: tt.titleSmall?.copyWith(color: cs.primary, fontWeight: FontWeight.bold),
                    ),
                    onTap: () => Get.offAllNamed<void>(AppRoutes.login),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                );
              }

              return Container(
                decoration: BoxDecoration(
                  color: cs.errorContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.error.withValues(alpha: 0.3)),
                ),
                child: ListTile(
                  leading:
                      Icon(Icons.logout_rounded, color: cs.error, size: 22),
                  title: Text(
                    'Sign Out',
                    style: tt.titleSmall?.copyWith(color: cs.error),
                  ),
                  onTap: () => _confirmLogout(context, session),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkTile(BuildContext context, CustomLink link,
      {required bool showDivider}) {
    final cs = context.contextTheme.colorScheme;
    final tt = context.contextTheme.textTheme;

    return Column(
      children: [
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Icon(
            _iconFromName(link.icon),
            color: cs.primary,
            size: 22,
          ),
          title: Text(
            link.title,
            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w500),
          ),
          trailing:
              Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
          onTap: () => Get.toNamed<void>(
            AppRoutes.webview,
            arguments: WebViewArgs(url: link.url, title: link.title),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
                showDivider ? 0 : 16),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: cs.outlineVariant,
          ),
      ],
    );
  }

  IconData _iconFromName(String? name) {
    return switch (name) {
      'web' || 'website' || 'link' => Icons.language_rounded,
      'support' || 'help' => Icons.help_outline_rounded,
      'news' || 'article' => Icons.article_outlined,
      'map' || 'location' => Icons.place_outlined,
      'phone' || 'call' => Icons.phone_outlined,
      'email' || 'mail' => Icons.email_outlined,
      'document' || 'file' => Icons.description_outlined,
      _ => Icons.open_in_new_rounded,
    };
  }

  void _confirmLogout(BuildContext context, SessionController session) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              session.logout();
            },
            child: Text(
              'Sign Out',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
