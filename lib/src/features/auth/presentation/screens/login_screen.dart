import 'package:circa_flow_main/src/imports/core_imports.dart';
import 'package:circa_flow_main/src/imports/packages_imports.dart';
import 'package:circa_flow_main/src/config/config_controller.dart';
import 'package:circa_flow_main/src/features/auth/presentation/providers/auth_controller.dart';

class LoginScreen extends HookWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();
    final configCtrl = Get.find<ConfigController>();

    final formKey = useMemoized(() => GlobalKey<FormState>());
    final identifierController = useTextEditingController();
    final passwordController = useTextEditingController();
    final obscurePassword = useState(true);

    final cs = context.contextTheme.colorScheme;
    final tt = context.contextTheme.textTheme;

    void handleLogin() {
      if (!(formKey.currentState?.validate() ?? false)) return;
      controller.login(
        context: context,
        identifier: identifierController.text.trim(),
        password: passwordController.text,
      );
    }

    return Obx(() {
      final isLoading = controller.isLoading.value;
      final orgName = configCtrl.orgName;
      final logoUrl = configCtrl.logoUrl;

      return Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding:
                  EdgeInsets.symmetric(horizontal: AppSpacing.lg.w),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: AppSpacing.xxxl.h),

                    // --- Branding ---
                    if (logoUrl != null)
                      AppCachedImage(
                        imageUrl: logoUrl,
                        width: 72,
                        height: 72,
                      )
                    else
                      Icon(
                        Icons.circle_rounded,
                        size: 64,
                        color: cs.primary,
                      ),
                    SizedBox(height: AppSpacing.md.h),
                    Text(
                      orgName,
                      style: tt.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm.h),
                    Text(
                      'Sign in to your account',
                      textAlign: TextAlign.center,
                      style: tt.bodyMedium
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    SizedBox(height: AppSpacing.xxxl.h),

                    // --- Identifier field (email or phone) ---
                    AppTextField(
                      controller: identifierController,
                      enabled: !isLoading,
                      label: 'Email or Phone',
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (AppUtils.isBlank(v)) {
                          return 'Please enter your email or phone';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: AppSpacing.md.h),

                    // --- Password field ---
                    AppTextField(
                      controller: passwordController,
                      enabled: !isLoading,
                      label: 'auth.password'.t(),
                      obscureText: obscurePassword.value,
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword.value
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () =>
                            obscurePassword.value = !obscurePassword.value,
                      ),
                      validator: (v) {
                        if (AppUtils.isBlank(v)) {
                          return 'auth.password_required'.t();
                        }
                        if (v!.length < 6) {
                          return 'auth.password_too_short'.t();
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: AppSpacing.lg.h),

                    // --- Sign In Button ---
                    AppButton(
                      label: 'Sign In',
                      isLoading: isLoading,
                      onPressed: isLoading ? null : handleLogin,
                      isFullWidth: true,
                    ),
                    SizedBox(height: AppSpacing.xxxl.h),

                    // --- Contact support note ---
                    Text(
                      'Don\'t have an account? Contact your organisation admin.',
                      textAlign: TextAlign.center,
                      style: tt.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    SizedBox(height: AppSpacing.xl.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
