import 'dart:io';

import 'package:circa_flow_main/src/imports/core_imports.dart';
import 'package:circa_flow_main/src/imports/packages_imports.dart';
import 'package:circa_flow_main/src/shared/constants/app_constants.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// A non-dismissible screen that blocks access when the installed app version
/// is below the backend-mandated minimum.
///
/// The user CANNOT go back (Android back gesture / button is blocked).
/// They can only tap "Update Now" which opens the appropriate store.
class ForceUpdateScreen extends StatefulWidget {
  const ForceUpdateScreen({super.key});

  @override
  State<ForceUpdateScreen> createState() => _ForceUpdateScreenState();
}

class _ForceUpdateScreenState extends State<ForceUpdateScreen> {
  String _currentVersion = '';
  String _currentBuild = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _currentVersion = info.version;
        _currentBuild = info.buildNumber;
      });
    }
  }

  Future<void> _launchStore() async {
    final configCtrl = Get.find<ConfigController>();
    final String? url = Platform.isIOS
        ? configCtrl.appStoreUrl
        : configCtrl.playStoreUrl;

    if (url == null || url.isEmpty) {
      // Fallback: open generic market URI (Android) or App Store (iOS)
      final fallback = Platform.isIOS
          ? 'https://apps.apple.com'
          : 'market://details?id=${await _packageName()}';
      await _openUrl(fallback);
      return;
    }
    await _openUrl(url);
  }

  Future<String> _packageName() async {
    final info = await PackageInfo.fromPlatform();
    return info.packageName;
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final configCtrl = Get.find<ConfigController>();
    final cs = context.contextTheme.colorScheme;
    final tt = context.contextTheme.textTheme;

    return PopScope(
      // Block back navigation — user MUST update.
      canPop: false,
      child: Scaffold(
        backgroundColor: cs.surface,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Column(
              children: [
                const Spacer(flex: 3),

                // Branded Logo Container (Minimalist Flat)
                Container(
                  width: 100.w,
                  height: 100.w,
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(28.w),
                    border: Border.all(
                      color: cs.primary.withValues(alpha: 0.1),
                      width: 1.5,
                    ),
                  ),
                  child: Image.asset(
                    AppConstants.appLogo,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.rocket_launch_rounded,
                      size: 40.w,
                      color: cs.primary,
                    ),
                  ),
                ),
                SizedBox(height: 40.h),

                // Information Header
                Text(
                  'Update Required',
                  style: tt.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: cs.onSurface,
                    letterSpacing: -0.8,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.h),
                Text(
                  'To continue using ${configCtrl.orgName}, please install the latest version to access new features and security updates.',
                  style: tt.bodyLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.6,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 48.h),

                // Progress-style Version Comparison
                if (_currentVersion.isNotEmpty)
                  _buildVersionProgression(context),

                const Spacer(flex: 4),

                // Primary CTA
                AppButton(
                  label: 'Update Now',
                  onPressed: _launchStore,
                  isFullWidth: true,
                  height: ButtonSize.medium,
                  prefixIcon: Icon(
                    Icons.file_download_outlined,
                    size: 20.sp,
                    color: cs.onPrimary,
                  ),
                ),
                SizedBox(height: 16.h),
                
                // Secondary Info
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      size: 12.sp,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'Secure update via official store',
                      style: tt.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVersionProgression(BuildContext context) {
    final cs = context.contextTheme.colorScheme;
    final configCtrl = Get.find<ConfigController>();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: AppBorders.card,
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _versionStep(
            context,
            label: 'Current',
            version: 'v$_currentVersion ($_currentBuild)',
            isActive: false,
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: cs.outlineVariant,
            size: 24.sp,
          ),
          _versionStep(
            context,
            label: 'Latest',
            version: 'v${configCtrl.minAppVersion} (${configCtrl.minBuildNumber})',
            isActive: true,
          ),
        ],
      ),
    );
  }

  Widget _versionStep(
    BuildContext context, {
    required String label,
    required String version,
    required bool isActive,
  }) {
    final tt = context.contextTheme.textTheme;
    final cs = context.contextTheme.colorScheme;
    final color = isActive ? cs.primary : cs.onSurfaceVariant.withValues(alpha: 0.6);

    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: tt.labelSmall?.copyWith(
            color: cs.onSurfaceVariant.withValues(alpha: 0.5),
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: isActive ? cs.primary.withValues(alpha: 0.08) : cs.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? cs.primary.withValues(alpha: 0.2) : cs.outlineVariant,
              width: 1,
            ),
          ),
          child: Text(
            version,
            style: tt.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
