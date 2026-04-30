import 'package:circa_flow_main/src/imports/core_imports.dart';
import 'package:circa_flow_main/src/imports/packages_imports.dart';


import 'package:circa_flow_main/src/features/auth/presentation/providers/auth_controller.dart';

class SignupScreen extends HookWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();
    final GlobalKey<FormState> formKey =
        useMemoized(() => GlobalKey<FormState>());
    final nameController = useTextEditingController();
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final confirmPasswordController = useTextEditingController();
    final obscurePassword = useState(true);
    final obscureConfirmPassword = useState(true);

    final isLoading = controller.isLoading.value;

    final cs = context.contextTheme.colorScheme;
    final tt = context.contextTheme.textTheme;

    Future<void> handleSignup() async {
      if (!(formKey.currentState?.validate() ?? false)) {
        return;
      }

       controller.signUp(
        context: context, 
        name: nameController.text,
        email: emailController.text, 
        password: passwordController.text,
      );
    }

    return Obx(() {
      final isLoading = controller.isLoading.value;
      return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: AppSpacing.xl.h),
                Text(
                  'auth.create_account'.t(),
                  style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ).animate().fadeIn().slideY(begin: 0.2),
                SizedBox(height: AppSpacing.sm.h),
                Text(
                  'auth.create_account_subtitle'.t(),
                  textAlign: TextAlign.center,
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ).animate().fadeIn().slideY(begin: 0.2),
                SizedBox(height: AppSpacing.xxxl.h),
                // Form Card
                Form(
                  key: formKey,
                  child: Column(
                    children: [
                      AppTextField(
                        controller: nameController,
                        enabled: !isLoading,
                        label: 'auth.name'.t(),
                        prefixIcon: const Icon(Icons.person_outline),
                        validator: (v) => AppUtils.isBlank(v) ? 'auth.name_required'.t() : null,
                      ),
                      SizedBox(height: AppSpacing.md.h),
                      AppTextField(
                        controller: emailController,
                        enabled: !isLoading,
                        keyboardType: TextInputType.emailAddress,
                        label: 'auth.email'.t(),
                        prefixIcon: const Icon(Icons.email_outlined),
                        validator: (v) {
                          if (AppUtils.isBlank(v)) {
                            return 'auth.email_required'.t();
                          }
                          if (!AppUtils.isValidEmail(v!)) {
                            return 'auth.email_invalid'.t();
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: AppSpacing.md.h),
                      AppTextField(
                        controller: passwordController,
                        enabled: !isLoading,
                        label: 'auth.password'.t(),
                        obscureText: obscurePassword.value,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(obscurePassword.value ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => obscurePassword.value = !obscurePassword.value,
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
                      SizedBox(height: AppSpacing.md.h),
                      AppTextField(
                        controller: confirmPasswordController,
                        enabled: !isLoading,
                        label: 'auth.confirm_password'.t(),
                        obscureText: obscureConfirmPassword.value,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(obscureConfirmPassword.value ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => obscureConfirmPassword.value = !obscureConfirmPassword.value,
                        ),
                        validator: (v) {
                          if (AppUtils.isBlank(v)) {
                            return 'auth.confirm_password_required'.t();
                          }
                          if (v != passwordController.text) {
                            return 'auth.passwords_do_not_match'.t();
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: AppSpacing.lg.h),
                      AppButton(
                        label: 'Create Account',
                        isLoading: isLoading,
                        onPressed: isLoading ? null : handleSignup,
                        width: ButtonSize.large,
                        isFullWidth: false,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.xxxl.h),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 20.w,
                      children: [
                        SizedBox(
                          width: 50.w,
                          height: 50.w,
                          child: TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFFEA4335).withValues(alpha: 0.8),
                              padding: EdgeInsets.symmetric(horizontal: 10.w),
                              shape: const RoundedRectangleBorder(
                                borderRadius: AppBorders.button,
                              ),
                            ),
                            child: SvgPicture.asset(AppAssets.googleIcon),
                          ),
                        ),
                        SizedBox(
                          width: 50.w,
                          height: 50.w,
                          child: TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFF4285F4),
                              padding: EdgeInsets.symmetric(horizontal: 10.w),
                              shape: const RoundedRectangleBorder(
                                borderRadius: AppBorders.button,
                              ),
                            ),
                            child: SvgPicture.asset(AppAssets.facebookIcon),
                          ),
                        ),
                        SizedBox(
                          width: 50.w,
                          height: 50.w,
                          child: TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFF000000),
                              padding: EdgeInsets.symmetric(horizontal: 10.w),
                              shape: const RoundedRectangleBorder(
                                borderRadius: AppBorders.button,
                              ),
                            ),
                            child: SvgPicture.asset(AppAssets.appleIcon),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.xl.h),
                  ],
                ),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: RichText(
                    text: TextSpan(
                      text: 'auth.already_have_account'.t(),
                      style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                      children: [
                        TextSpan(
                          text: 'auth.sign_up'.t(),
                          style: TextStyle(
                            color: cs.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.xl.h),
              ],
            ),
          ),
        ),
      ),
    );
    });
  }
}
