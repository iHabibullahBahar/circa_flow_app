import 'package:circa_flow_main/src/imports/core_imports.dart';
import 'package:circa_flow_main/src/imports/packages_imports.dart';
import 'package:circa_flow_main/src/config/config_controller.dart';
import 'package:circa_flow_main/src/features/auth/presentation/providers/auth_controller.dart';
import 'package:circa_flow_main/src/theme/color_schemes.dart';

class SignupScreen extends HookWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();
    final configCtrl = Get.find<ConfigController>();

    final formKey = useMemoized(() => GlobalKey<FormState>());
    final nameController = useTextEditingController();
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final confirmPasswordController = useTextEditingController();
    final obscurePassword = useState(true);
    final obscureConfirmPassword = useState(true);
    final cs = context.contextTheme.colorScheme;
    final tt = context.contextTheme.textTheme;

    void handleSignup() {
      if (!(formKey.currentState?.validate() ?? false)) return;
      controller.register(
        context: context,
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
        passwordConfirmation: confirmPasswordController.text,
      );
    }

    return Obx(() {
      final isLoading = controller.isLoading.value;
      final orgName = configCtrl.orgName;

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
            'Join $orgName',
            style: tt.titleLarge?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  Text(
                    'Create an account',
                    style: tt.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                      fontSize: 28.sp,
                    ),
                  ),
                  const SizedBox(height: 32),

                  AppTextField(
                    label: 'Full Name',
                    controller: nameController,
                    hint: 'John Doe',
                    keyboardType: TextInputType.name,
                    enabled: !isLoading,
                    autofillHints: const [AutofillHints.name],
                    validator: (v) =>
                        AppUtils.isBlank(v) ? 'Please enter your name' : null,
                  ),

                  const SizedBox(height: 20),

                  AppTextField(
                    label: 'Email Address',
                    controller: emailController,
                    hint: 'name@gmail.com',
                    keyboardType: TextInputType.emailAddress,
                    enabled: !isLoading,
                    autofillHints: const [AutofillHints.email],
                    validator: (v) {
                      if (AppUtils.isBlank(v)) return 'Please enter your email';
                      if (!GetUtils.isEmail(v!))
                        return 'Please enter a valid email';
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  AppTextField(
                    label: 'Password',
                    controller: passwordController,
                    hint: 'Minimum 8 characters',
                    obscureText: obscurePassword.value,
                    enabled: !isLoading,
                    autofillHints: const [AutofillHints.newPassword],
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
                      if (AppUtils.isBlank(v)) return 'Please enter a password';
                      if (v!.length < 8) return 'Minimum 8 characters required';
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  AppTextField(
                    label: 'Confirm Password',
                    controller: confirmPasswordController,
                    hint: 'Re-type your password',
                    obscureText: obscureConfirmPassword.value,
                    enabled: !isLoading,
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirmPassword.value
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: cs.onSurfaceVariant,
                      ),
                      onPressed: () => obscureConfirmPassword.value =
                          !obscureConfirmPassword.value,
                    ),
                    validator: (v) {
                      if (v != passwordController.text)
                        return 'Passwords do not match';
                      return null;
                    },
                  ),

                  const SizedBox(height: 32),

                  // --- Action Button ---
                  AppButton(
                    label: 'Create Account',
                    onPressed: handleSignup,
                    isLoading: isLoading,
                    isFullWidth: true,
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
