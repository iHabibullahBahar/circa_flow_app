import '../../../imports/imports.dart';
import 'toast.dart';
import 'toast_card.dart';

class AppToast {
  static void success(String message, {String? title}) {
    _show(
      title: title ?? 'Success',
      message: message,
      icon: Icons.check_circle_rounded,
      color: Colors.green,
    );
  }

  static void error(String message, {String? title}) {
    _show(
      title: title ?? 'Error',
      message: message,
      icon: Icons.error_rounded,
      color: Colors.red,
    );
  }

  static void info(String message, {String? title}) {
    _show(
      title: title ?? 'Info',
      message: message,
      icon: Icons.info_rounded,
      color: Colors.blue,
    );
  }

  static void _show({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
  }) {
    final context = Get.context;
    if (context == null) return;

    ToastBar(
      autoDismiss: true,
      position: ToastPosition.top,
      builder: (context) => ToastCard(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(message),
        leading: Icon(icon, color: color),
      ),
    ).show(context);
  }
}
