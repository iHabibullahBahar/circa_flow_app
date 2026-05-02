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
                child: Icon(icon, color: iconColor ?? Colors.blue[700], size: 32),
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
}
