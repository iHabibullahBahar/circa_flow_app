import 'package:circa_flow_main/src/imports/core_imports.dart';
import 'package:circa_flow_main/src/imports/packages_imports.dart';
import 'package:circa_flow_main/src/config/config_controller.dart';
import 'package:circa_flow_main/src/features/auth/presentation/providers/auth_controller.dart';
import 'package:circa_flow_main/src/theme/color_schemes.dart';

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
        backgroundColor: cs.surface,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    if (logoUrl != null)
                      Center(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: cs.onSurface.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: AppCachedImage(
                              imageUrl: logoUrl,
                              width: 64,
                              height: 64,
                            ),
                          ),
                        ),
                      )
                    else
                      Center(
                        child: Icon(Icons.circle_rounded,
                            size: 64, color: cs.primary),
                      ),
                    const SizedBox(height: 24),
                    Center(
                      child: Text(
                        'Welcome back',
                        textAlign: TextAlign.center,
                        style: tt.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                          fontSize: 28.sp,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Welcome back! Please enter your details.',
                        textAlign: TextAlign.center,
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    AppTextField(
                      label: 'Email',
                      controller: identifierController,
                      hint: 'Enter your email',
                      keyboardType: TextInputType.emailAddress,
                      enabled: !isLoading,
                      autofillHints: const [
                        AutofillHints.email,
                        AutofillHints.username
                      ],
                      validator: (v) =>
                          AppUtils.isBlank(v) ? 'Enter your email' : null,
                    ),
                    const SizedBox(height: 20),
                    AppTextField(
                      label: 'Password',
                      controller: passwordController,
                      hint: 'Enter your password',
                      obscureText: obscurePassword.value,
                      enabled: !isLoading,
                      autofillHints: const [AutofillHints.password],
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword.value
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                          color: cs.onSurfaceVariant,
                        ),
                        onPressed: () =>
                            obscurePassword.value = !obscurePassword.value,
                      ),
                      validator: (v) {
                        if (AppUtils.isBlank(v)) return 'Enter your password';
                        if (v!.length < 6) return 'Password too short';
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () =>
                            Get.toNamed<void>(AppRoutes.forgotPassword),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: cs.primary,
                        ),
                        child: Text(
                          'Forgot Password?',
                          style: tt.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      label: 'Sign In',
                      onPressed: handleLogin,
                      isLoading: isLoading,
                      isFullWidth: true,
                    ),
                    const SizedBox(height: 24),
                    if (configCtrl.allowRegistration)
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: tt.bodyMedium
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                            GestureDetector(
                              onTap: () => Get.toNamed<void>(AppRoutes.signup),
                              child: Text(
                                'Sign Up',
                                style: tt.bodyMedium?.copyWith(
                                  color: cs.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 48),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'By proceeding, you consent to the terms of service and privacy policy of $orgName.',
                          textAlign: TextAlign.center,
                          style: tt.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
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
