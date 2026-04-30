import 'package:circa_flow_main/src/imports/core_imports.dart';
import 'package:circa_flow_main/src/imports/packages_imports.dart';

/// Placeholder screen — password reset is not supported by the current backend.
/// Shows a message directing the user to contact their admin.
class ForgotPasswordScreen extends HookWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = context.contextTheme.colorScheme;
    final tt = context.contextTheme.textTheme;

    return Scaffold(
      appBar: const AppTopBar(title: ''),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_reset_rounded,
                  size: 64,
                  color: cs.primary,
                ),
                SizedBox(height: AppSpacing.xl.h),
                Text(
                  'Password Reset',
                  style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.md.h),
                Text(
                  'To reset your password, please contact your organisation administrator.',
                  textAlign: TextAlign.center,
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
                SizedBox(height: AppSpacing.xxxl.h),
                AppButton(
                  label: 'Back to Sign In',
                  variant: ButtonVariant.outline,
                  onPressed: () => Get.back<void>(),
                  isFullWidth: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
