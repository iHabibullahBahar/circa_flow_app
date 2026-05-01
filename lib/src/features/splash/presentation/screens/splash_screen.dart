import 'package:circa_flow_main/src/imports/imports.dart';

/// Shown at startup while the config is being fetched and the auth state
/// is being resolved. Uses Obx to react to ConfigController status changes
/// and then hands off to SessionListenerWrapper which drives navigation.
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../shared/constants/app_constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
    // Remove the native splash screen to reveal this custom Flutter splash screen
    FlutterNativeSplash.remove();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = 'v${info.version} (${info.buildNumber})';
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.contextTheme.colorScheme;
    final tt = context.contextTheme.textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(
        children: [
          // Main Content (Logo & Name)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Image.asset(
                  AppConstants.appLogo,
                  width: 140,
                  height: 140,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.circle_rounded,
                    size: 80,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(height: 24),

                // App Name
                Text(
                  AppConstants.appName,
                  style: tt.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),

          // Loading Indicator & Version Info at Bottom
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _version,
                  textAlign: TextAlign.center,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
