import 'package:circa_flow_main/src/imports/core_imports.dart';
import 'package:circa_flow_main/src/imports/packages_imports.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';

/// Sits above the navigator and checks whether the currently installed
/// app version meets the backend's minimum requirement.
///
/// - On first config ready (from network or cache), compares [PackageInfo]
///   version to [ConfigController.minAppVersion] using semantic versioning.
/// - If the installed version is too old, replaces the entire navigation
///   stack with [AppRoutes.forceUpdate] — a non-dismissible screen.
/// - Runs the check only once per app lifecycle (guarded by [_checked]).
class VersionCheckWrapper extends StatefulWidget {
  final Widget child;
  const VersionCheckWrapper({super.key, required this.child});

  @override
  State<VersionCheckWrapper> createState() => _VersionCheckWrapperState();
}

class _VersionCheckWrapperState extends State<VersionCheckWrapper> {
  Worker? _configWorker;
  // Synchronous flag — set BEFORE the async work so the ever() guard
  // sees it immediately and never fires a second run.
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    // Use post-frame to ensure GetX controllers are fully ready.
    WidgetsBinding.instance.addPostFrameCallback((_) => _setupListener());
  }

  void _setupListener() {
    final configCtrl = Get.find<ConfigController>();

    // Run immediately if config is already ready (fast cache hit).
    if (configCtrl.status.value == ConfigStatus.ready) {
      _triggerCheck(configCtrl);
      return;
    }

    // Otherwise wait for the config to finish loading.
    _configWorker = ever(configCtrl.status, (ConfigStatus status) {
      if (status == ConfigStatus.ready) {
        _triggerCheck(configCtrl);
      }
    });
  }

  /// Guards against double-runs and kicks off the async check.
  void _triggerCheck(ConfigController configCtrl) {
    if (_checked) return;
    _checked = true; // Set synchronously BEFORE the async call.
    _configWorker?.dispose();
    _configWorker = null;
    _runVersionCheck(configCtrl);
  }

  Future<void> _runVersionCheck(ConfigController configCtrl) async {
    final minVersionStr = configCtrl.minAppVersion;

    // Only skip enforcement if the version is explicitly empty or '0.0.0'.
    // We allow 1.0.0 because an admin might want to force a specific build number 
    // for the very first release version.
    if (minVersionStr.isEmpty || minVersionStr == '0.0.0') {
      return;
    }

    PackageInfo info;
    try {
      info = await PackageInfo.fromPlatform();
    } catch (e) {
      return;
    }

    final localVersionStr = info.version;
    final localBuildStr = info.buildNumber;

    try {
      final minVersion = Version.parse(minVersionStr);
      final localVersion = Version.parse(localVersionStr);
      
      final minBuild = configCtrl.minBuildNumber;
      final localBuild = int.tryParse(localBuildStr) ?? 0;

      // Enforcement logic:
      // 1. If major.minor.patch is strictly lower -> Force Update.
      // 2. If major.minor.patch is the same, but the internal build number 
      //    is lower -> Force Update.
      final isVersionOutdated = localVersion < minVersion;
      final isBuildOutdated = (localVersion == minVersion) && (localBuild < minBuild);

      if (isVersionOutdated || isBuildOutdated) {
        // Replace the entire stack so back navigation is impossible.
        Get.offAllNamed<void>(AppRoutes.forceUpdate);
      }
    } catch (e) {
      // Malformed version string — skip enforcement to avoid bricking the app.
    }
  }

  @override
  void dispose() {
    _configWorker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
