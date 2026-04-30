import 'package:circa_flow_main/src/imports/core_imports.dart';
import 'package:circa_flow_main/src/imports/packages_imports.dart';


import 'package:circa_flow_main/src/features/auth/presentation/providers/auth_controller.dart';

class ForgotPasswordScreen extends HookWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();
    final GlobalKey<FormState> formKey =
        useMemoized(() => GlobalKey<FormState>());
    final emailController = useTextEditingController();

    final isLoading = controller.isLoading.value;

    final cs = context.contextTheme.colorScheme;
    final tt = context.contextTheme.textTheme;

    Future<void> handleForgotPassword() async {
      if (!(formKey.currentState?.validate() ?? false)) {
        return;
      }

      controller.forgotPassword(
        context: context, 
        email: emailController.text,
      );
    }

    return Obx(() {
      final isLoading = controller.isLoading.value;
      return Scaffold(
      appBar: const AppTopBar(title: ''),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: AppSpacing.xl.h),
                Text(
                  'auth.forgot_password_title'.t(),
                  style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: AppSpacing.sm.h),
                Text(
                  'auth.forgot_password_subtitle'.t(),
                  textAlign: TextAlign.center,
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
                SizedBox(height: AppSpacing.xxxl.h),
                // Form Card
                Form(
                  key: formKey,
                  child: Column(
                    children: [
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
                      SizedBox(height: AppSpacing.lg.h),
                      AppButton(
                        label: 'Send Reset Link',
                        isLoading: isLoading,
                        onPressed: isLoading ? null : handleForgotPassword,
                        width: ButtonSize.large,
                        isFullWidth: false,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.xxxl.h),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'auth.back_to_login'.t(),
                    style: tt.labelLarge?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.bold,
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
