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
                        child: Icon(Icons.circle_rounded, size: 64, color: cs.primary),
                      ),
                      
                    const SizedBox(height: 24),

                    Center(
                      child: Text(
                        'Get started with $orgName',
                        textAlign: TextAlign.center,
                        style: tt.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                          fontSize: 28.sp,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 48),

                    Text(
                      'Email or Phone',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _UberTextField(
                      controller: identifierController,
                      hintText: 'Enter your email',
                      keyboardType: TextInputType.emailAddress,
                      enabled: !isLoading,
                      validator: (v) => AppUtils.isBlank(v) ? 'Enter your email' : null,
                    ),
                    
                    const SizedBox(height: 20),

                    Text(
                      'Password',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _UberTextField(
                      controller: passwordController,
                      hintText: 'Enter your password',
                      obscureText: obscurePassword.value,
                      enabled: !isLoading,
                      suffix: IconButton(
                        icon: Icon(
                          obscurePassword.value
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                          color: cs.onSurfaceVariant,
                        ),
                        onPressed: () => obscurePassword.value = !obscurePassword.value,
                      ),
                      validator: (v) {
                        if (AppUtils.isBlank(v)) return 'Enter your password';
                        if (v!.length < 6) return 'Password too short';
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cs.primary,
                          foregroundColor: cs.onPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          disabledBackgroundColor: cs.outlineVariant,
                        ),
                        child: isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: cs.onPrimary,
                                ),
                              )
                            : Text(
                                'Continue',
                                style: tt.titleMedium?.copyWith(
                                  color: cs.onPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18.sp,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    
                    Row(
                      children: [
                        Expanded(child: Divider(color: cs.outlineVariant)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'or',
                            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ),
                        Expanded(child: Divider(color: cs.outlineVariant)),
                      ],
                    ),
                    
                    const SizedBox(height: 24),

                    if (configCtrl.allowGuestAccess)
                      _UberSecondaryButton(
                        label: 'Continue as Guest',
                        icon: Icons.person_outline_rounded,
                        onPressed: () => Get.offAllNamed<void>(AppRoutes.home),
                      ),
                    
                    if (configCtrl.allowRegistration) ...[
                      const SizedBox(height: 12),
                      _UberSecondaryButton(
                        label: 'Create an account',
                        icon: Icons.add_circle_outline_rounded,
                        onPressed: () => Get.toNamed<void>(AppRoutes.signup),
                      ),
                    ],
                    
                    const SizedBox(height: 48),

                    Center(
                      child: Column(
                        children: [
                          TextButton(
                            onPressed: () => Get.toNamed<void>(AppRoutes.forgotPassword),
                            child: Text(
                              'Find my account / Forgot Password',
                              style: tt.bodyMedium?.copyWith(
                                color: cs.onSurface,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
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
                        ],
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

class _UberTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final bool enabled;
  final Widget? suffix;
  final String? Function(String?)? validator;

  const _UberTextField({
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.enabled = true,
    this.suffix,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      enabled: enabled,
      validator: validator,
      style: context.contextTheme.textTheme.bodyLarge?.copyWith(
        color: context.contextTheme.colorScheme.onSurface,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: context.contextTheme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
        filled: true,
        fillColor: context.appColors.placeholder.withValues(alpha: 0.3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: context.appColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: context.appColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: context.contextTheme.colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: context.contextTheme.colorScheme.error, width: 1),
        ),
        suffixIcon: suffix,
      ),
    );
  }
}

class _UberSecondaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _UberSecondaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.contextTheme.colorScheme;
    final tt = context.contextTheme.textTheme;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: context.appColors.placeholder.withValues(alpha: 0.3),
          side: BorderSide(color: context.appColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          foregroundColor: cs.onSurface,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: tt.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
