import 'package:get/get.dart';
import 'src/imports/core_imports.dart';
import 'src/imports/packages_imports.dart';
import 'src/config/config_controller.dart';
import 'src/features/auth/domain/repositories/auth_repository.dart';
import 'src/features/auth/data/repositories/auth_repository_impl.dart';
import 'src/features/auth/presentation/providers/session_controller.dart';
import 'src/features/auth/presentation/providers/auth_controller.dart';
import 'src/app.dart';

Future<void> main() async {
  final WidgetsBinding widgetsBinding =
      WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await EasyLocalization.ensureInitialized();
  await dotenv.load(fileName: '.env');

  await AppConfig.init();

  // OneSignal Initialization
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize("41000094-b38b-4010-a480-d376696fe1e3");
  OneSignal.Notifications.requestPermission(true);

  // Register permanent controllers BEFORE runApp so they are available
  // the moment the widget tree starts building (App.build calls Get.find).
  Get.put<ConfigController>(ConfigController(), permanent: true);

  Get.lazyPut<AuthRepository>(() => AuthRepositoryImpl(), fenix: true);

  Get.put<SessionController>(
    SessionController(repository: Get.find<AuthRepository>()),
    permanent: true,
  );

  Get.lazyPut<AuthController>(
    () => AuthController(repository: Get.find<AuthRepository>()),
    fenix: true,
  );

  runApp(
    const LocalizationWrapper(
      child: StateWrapper(
        child: App(),
      ),
    ),
  );
}