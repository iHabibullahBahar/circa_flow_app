import 'package:circa_flow_main/src/imports/core_imports.dart';
import 'package:circa_flow_main/src/imports/packages_imports.dart';

/// Sign-up is not supported by this backend.
/// This screen is kept as a graceful fallback placeholder.
class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

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
                Icon(Icons.person_add_disabled_rounded,
                    size: 64, color: cs.onSurfaceVariant),
                SizedBox(height: AppSpacing.xl.h),
                Text(
                  'Registration Unavailable',
                  style: tt.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.md.h),
                Text(
                  'New account creation is handled by your organisation administrator.',
                  textAlign: TextAlign.center,
                  style:
                      tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
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
