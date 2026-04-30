import 'package:circa_flow_main/src/imports/imports.dart';

/// A wrapper to initialize [EasyLocalization] with supported locales.
class LocalizationWrapper extends StatelessWidget {
  final Widget child;

  const LocalizationWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('de'),
        Locale('fr'),
        Locale('pt'),
        Locale('it'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: child,
    );
  }
}
