import '../../imports/imports.dart';

/// A utility class for showing consistent, branded dialogs across the app.
class AppDialogs {
  /// Shows a premium confirmation dialog.
  static void showConfirm({
    required String title,
    required String description,
    required String confirmLabel,
    required VoidCallback onConfirm,
    String cancelLabel = 'Cancel',
    IconData icon = Icons.info_outline,
    Color? iconColor,
    Color? iconBgColor,
    ButtonVariant confirmVariant = ButtonVariant.primary,
  }) {
    Get.dialog<void>(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: iconBgColor ?? Colors.blue[50],
                  shape: BoxShape.circle,
                ),
                child:
                    Icon(icon, color: iconColor ?? Colors.blue[700], size: 32),
              ),
              const Gap(20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const Gap(12),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              const Gap(32),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: cancelLabel,
                      variant: ButtonVariant.ghost,
                      height: ButtonSize.small,
                      onPressed: () => Get.back<void>(),
                    ),
                  ),
                  const Gap(8),
                  Expanded(
                    child: AppButton(
                      label: confirmLabel,
                      variant: confirmVariant,
                      height: ButtonSize.small,
                      onPressed: () {
                        Get.back<void>();
                        onConfirm();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows a beautiful bottom sheet modal prompting guest users to log in.
  static void showLoginRequiredBottomSheet(BuildContext context) {
    final cs = context.contextTheme.colorScheme;
    final tt = context.contextTheme.textTheme;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
              24, 12, 24, MediaQuery.of(context).padding.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              // Center(
              //   child: Container(
              //     width: 48,
              //     height: 4,
              //     margin: const EdgeInsets.only(bottom: 24),
              //     decoration: BoxDecoration(
              //       color: cs.onSurfaceVariant.withValues(alpha: 0.2),
              //       borderRadius: BorderRadius.circular(2),
              //     ),
              //   ),
              // ),

              // Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_person_rounded,
                  size: 48,
                  color: cs.primary,
                ),
              ),
              const Gap(24),

              // Text Content
              Text(
                'Login Required',
                style: tt.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: cs.onSurface,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const Gap(12),
              Text(
                'You need to log in or create an account to access this feature and connect with others.',
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const Gap(32),

              // Actions
              AppButton(
                label: 'Sign In',
                onPressed: () {
                  Get.back<void>();
                  Get.toNamed<void>(AppRoutes.login);
                },
                variant: ButtonVariant.primary,
                isFullWidth: true,
              ),
              const Gap(12),
              AppButton(
                label: 'Cancel',
                onPressed: () => Get.back<void>(),
                variant: ButtonVariant.ghost,
                isFullWidth: true,
              ),
            ],
          ),
        );
      },
    );
  }
}
