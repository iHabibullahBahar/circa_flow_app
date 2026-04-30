import 'package:circa_flow_main/src/imports/imports.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final current = _buildMaterialApp(context);
    return ScreenUtilWrapper(child: current);
  }

  Widget _buildMaterialApp(BuildContext context) {
    return GetMaterialApp(
      initialBinding: AppBindings(),
      title: 'Circa Flow Main',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(primaryColorHex: '#1447e6'),
      darkTheme: buildDarkTheme(primaryColorHex: '#1447e6'),
      themeMode: ThemeMode.system,
      initialRoute: AppRoutes.onboarding,
      getPages: AppRouter.getPages,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      builder: (context, child) {
        Widget current = child!;
        current = SkeletonWrapper(child: current);
        current = SessionListenerWrapper(child: current);
        return current;
      },
    );
  }
}