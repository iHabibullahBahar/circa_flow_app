import 'package:circa_flow_main/src/imports/imports.dart';
import 'package:circa_flow_main/src/config/config_controller.dart';

/// Shown at startup while the config is being fetched and the auth state
/// is being resolved. Uses Obx to react to ConfigController status changes
/// and then hands off to SessionListenerWrapper which drives navigation.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final configCtrl = Get.find<ConfigController>();
    final cs = context.contextTheme.colorScheme;
    final tt = context.contextTheme.textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Center(
        child: Obx(() {
          final isError = configCtrl.status.value == ConfigStatus.error;
          final logoUrl = configCtrl.logoUrl;

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo / Branding
              if (logoUrl != null)
                AppCachedImage(
                  imageUrl: logoUrl,
                  width: 120,
                  height: 120,
                )
              else
                Icon(
                  Icons.circle_rounded,
                  size: 80,
                  color: cs.primary,
                ),
              const SizedBox(height: 24),

              // App Name
              Obx(() => Text(
                    configCtrl.orgName,
                    style: tt.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  )),
              const SizedBox(height: 40),

              // Status indicator
              if (isError) ...[
                Text(
                  'Could not connect. Using saved settings.',
                  textAlign: TextAlign.center,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: configCtrl.loadConfig,
                  child: const Text('Retry'),
                ),
              ] else
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: cs.primary,
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}
