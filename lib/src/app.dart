import 'package:circa_flow_main/src/imports/imports.dart';
import 'package:circa_flow_main/src/config/config_controller.dart';
import 'package:circa_flow_main/src/shared/wrappers/version_check_wrapper.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilWrapper(child: _buildMaterialApp(context));
  }

  Widget _buildMaterialApp(BuildContext context) {
    final configCtrl = Get.find<ConfigController>();

    return Obx(() {
      // Theme rebuilds reactively whenever config changes (e.g. after fetch)
      final primaryHex = configCtrl.primaryColor;

      return GetMaterialApp(
        initialBinding: AppBindings(),
        title: configCtrl.orgName,
        debugShowCheckedModeBanner: false,
        theme: buildLightTheme(primaryColorHex: primaryHex),
        darkTheme: buildDarkTheme(primaryColorHex: primaryHex),
        themeMode: ThemeMode.system,
        initialRoute: AppRoutes.splash,
        getPages: AppRouter.getPages,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        builder: (context, child) {
          Widget current = child!;
          current = SkeletonWrapper(child: current);
          current = VersionCheckWrapper(child: current);
          current = SessionListenerWrapper(child: current);
          return current;
        },
      );
    });
  }
}
