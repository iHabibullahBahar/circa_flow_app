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
      appBar: AppBar(
        title: Text(
          'Account & Settings',
          style: tt.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: const Color(0xFF1A334D), // Dark Navy like screenshot
            fontSize: 18.sp,
          ),
        ),
        centerTitle: true,
        backgroundColor: cs.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
              height: 1,
              color: context.appColors.border.withValues(alpha: 0.3)),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          // --- User Profile (Subtle) ---
          Obx(() {
            final user = session.user.value;
            final isAuthenticated = session.isAuthenticated;
            if (!isAuthenticated) return const SizedBox.shrink();

            return Container(
              padding: const EdgeInsets.all(20),
              color: cs.surface,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: cs.primary.withValues(alpha: 0.1),
                    child: Text(
                      (user?.name?.isNotEmpty == true ? user!.name![0] : 'U')
                          .toUpperCase(),
                      style: tt.titleLarge?.copyWith(
                          color: cs.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Member',
                          style: tt.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1A334D)),
                        ),
                        Text(
                          user?.email ?? '',
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

          // --- Services Section ---
          Obx(() {
            final buttons = configCtrl.customButtons;
            if (buttons.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(context, 'Services'),
                ...buttons.map((btn) => _buildLinkTile(context, btn)),
              ],
            );
          }),

          // --- Information Section ---
          Obx(() {
            final links = configCtrl.customLinks;
            if (links.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(context, 'Useful Links'),
                ...links.map((link) => _buildLinkTile(context, link)),
              ],
            );
          }),

          // --- Engagement Section ---
          _buildSectionHeader(context, 'Engagement'),
          _buildActionTile(
            context,
            label: 'Communities',
            icon: Icons.groups_rounded,
            onTap: () => Get.toNamed<void>(AppRoutes.communities),
          ),

          // --- Account Section ---
          _buildSectionHeader(context, 'Account'),
          Obx(() {
            final isGuest = !session.isAuthenticated;
            if (isGuest) {
              return _buildActionTile(
                context,
                label: 'Sign In',
                icon: Icons.login_rounded,
                onTap: () => Get.offAllNamed<void>(AppRoutes.login),
              );
            }

            return _buildActionTile(
              context,
              label: 'Sign Out',
              icon: Icons.logout_rounded,
              onTap: () => _confirmLogout(context, session),
              isDestructive: true,
            );
          }),

          const SizedBox(height: 40),
          Center(
            child: FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final version = snapshot.data?.version ?? '1.0.0';
                final build = snapshot.data?.buildNumber ?? '1';
                return Text(
                  'Version $version (Build $build)',
                  style: tt.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                    letterSpacing: 1,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final cs = context.contextTheme.colorScheme;
    final tt = context.contextTheme.textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 16, top: 24, bottom: 8),
      color:
          const Color(0xFFF8FAFC), // Very light grey background for header rows
      child: Text(
        title,
        style: tt.labelMedium?.copyWith(
          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
          fontSize: 11.sp,
        ),
      ),
    );
  }

  Widget _buildLinkTile(BuildContext context, CustomLink link) {
    return _buildActionTile(
      context,
      label: link.title,
      icon: Icons.description_rounded, // Force documents icon as requested
      onTap: () => Get.toNamed<void>(
        AppRoutes.webview,
        arguments: WebViewArgs(url: link.url, title: link.title),
      ),
    );
  }

  Widget _buildActionTile(BuildContext context,
      {required String label,
      required IconData icon,
      required VoidCallback onTap,
      bool isDestructive = false}) {
    final cs = context.contextTheme.colorScheme;
    final tt = context.contextTheme.textTheme;

    return Column(
      children: [
        ListTile(
          onTap: onTap,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          leading: Icon(
            icon,
            color: isDestructive
                ? cs.error.withValues(alpha: 0.7)
                : const Color(0xFF5E718D),
            size: 24,
          ),
          title: Text(
            label,
            style: tt.bodyLarge?.copyWith(
              color: isDestructive ? cs.error : const Color(0xFF1A334D),
              fontWeight: FontWeight.w600,
              fontSize: 15.sp,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: cs.onSurfaceVariant.withValues(alpha: 0.3),
            size: 20,
          ),
        ),
        Divider(
          height: 1,
          indent: 60,
          color: context.appColors.border.withValues(alpha: 0.3),
        ),
      ],
    );
  }

  void _confirmLogout(BuildContext context, SessionController session) {
    AppDialogs.showConfirm(
      title: 'Sign Out',
      description: 'Are you sure you want to sign out? You will need to log in again to access your account.',
      confirmLabel: 'Sign Out',
      icon: Icons.logout_rounded,
      iconColor: Colors.red[700],
      iconBgColor: Colors.red[50],
      confirmVariant: ButtonVariant.danger,
      onConfirm: () => session.logout(),
    );
  }
}
