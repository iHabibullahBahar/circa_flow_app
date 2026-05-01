import 'package:circa_flow_main/src/imports/core_imports.dart';
import 'package:circa_flow_main/src/imports/packages_imports.dart';
import 'package:circa_flow_main/src/features/auth/presentation/providers/auth_controller.dart';
import 'package:circa_flow_main/src/theme/color_schemes.dart';

class ForgotPasswordScreen extends HookWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final emailController = useTextEditingController();

    final cs = context.contextTheme.colorScheme;
    final tt = context.contextTheme.textTheme;

    void handleSendLink() {
      if (!(formKey.currentState?.validate() ?? false)) return;
      controller.forgotPassword(
        context: context,
        email: emailController.text.trim(),
      );
    }

    return Obx(() {
      final isLoading = controller.isLoading.value;

      return Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(
          backgroundColor: cs.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: cs.onSurface),
            onPressed: () => Get.back<void>(),
          ),
          title: Text(
            'Find my account',
            style: tt.titleLarge?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  
                  Text(
                    'Forgot Password?',
                    style: tt.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                      fontSize: 28.sp,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Enter your email address and we\'ll send you a link to reset your password on our website.',
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),

                  AppTextField(
                    label: 'Email Address',
                    controller: emailController,
                    hint: 'name@example.com',
                    keyboardType: TextInputType.emailAddress,
                    enabled: !isLoading,
                    validator: (v) {
                      if (AppUtils.isBlank(v)) return 'Please enter your email';
                      if (!GetUtils.isEmail(v!)) return 'Please enter a valid email';
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 32),

                  // --- Action Button ---
                  AppButton(
                    label: 'Next',
                    onPressed: handleSendLink,
                    isLoading: isLoading,
                    isFullWidth: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}


