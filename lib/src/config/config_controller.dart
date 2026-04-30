import 'package:get/get.dart';

import '../config/app_config_model.dart';
import '../services/config_service.dart';
import '../utils/utils.dart';

enum ConfigStatus { loading, ready, error }

/// Global config controller — registered as permanent so it lives for the
/// entire app lifecycle. All widgets that need branding/module data read from
/// this controller reactively via Obx.
class ConfigController extends GetxController {
  final Rx<AppConfigModel> config =
      Rx<AppConfigModel>(AppConfigModel.fallback());

  final Rx<ConfigStatus> status = ConfigStatus.loading.obs;

  // Convenience getters
  String get primaryColor => config.value.branding.primaryColor;
  String get orgName => config.value.organization.name;
  String? get logoUrl => config.value.branding.logoUrl;
  List<CustomLink> get customLinks => config.value.customLinks;
  List<CustomLink> get customButtons => config.value.customButtons;
  bool get allowRegistration => config.value.allowRegistration;
  bool get allowGuestAccess => config.value.allowGuestAccess;

  bool isModuleEnabled(String key) => config.value.modules.isEnabled(key);

  @override
  void onInit() {
    super.onInit();
    loadConfig();
  }

  /// Tries to fetch fresh config from the backend.
  /// Falls back to cached config on failure.
  /// Always resolves — never leaves the app in a permanently broken state.
  Future<void> loadConfig() async {
    status.value = ConfigStatus.loading;

    final result = await ConfigService.instance.fetchRemoteConfig();

    result.fold(
      (failure) async {
        AppLogger.warning('Remote config failed: ${failure.message}. Trying cache...');
        final cached = await ConfigService.instance.loadCachedConfig();
        if (cached != null) {
          config.value = cached;
          status.value = ConfigStatus.ready;
          AppLogger.info('✅ Config loaded from cache');
        } else {
          // Use built-in fallback so the app can still show a login screen
          config.value = AppConfigModel.fallback();
          status.value = ConfigStatus.error;
          AppLogger.error('❌ No config available — using fallback defaults');
        }
      },
      (freshConfig) {
        config.value = freshConfig;
        status.value = ConfigStatus.ready;
        AppLogger.info('✅ Config loaded from network: ${freshConfig.organization.name}');
      },
    );
  }
}
