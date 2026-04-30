import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../config/app_config_model.dart';
import '../utils/utils.dart';

/// Handles fetching the remote config and persisting it locally for offline use.
class ConfigService {
  ConfigService._();
  static final ConfigService instance = ConfigService._();

  static const _cacheKey = 'cached_app_config';

  /// Fetches config from POST /config and returns a typed model.
  FutureEither<AppConfigModel> fetchRemoteConfig() {
    return runTask(() async {
      final response = await AppConfig.dio.post<Map<String, dynamic>>('/config');
      final data = response.data;
      if (data == null) {
        throw Exception('Empty response from /config');
      }
      final model = AppConfigModel.fromJson(data);
      await _cacheConfig(model);
      return model;
    }, requiresNetwork: true);
  }

  /// Loads the last successfully fetched config from SharedPreferences.
  /// Returns null if nothing has been cached yet.
  Future<AppConfigModel?> loadCachedConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return AppConfigModel.fromJson(json);
    } catch (e) {
      AppLogger.warning('Failed to load cached config: $e');
      return null;
    }
  }

  Future<void> _cacheConfig(AppConfigModel model) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(model.toJson()));
    } catch (e) {
      AppLogger.warning('Failed to cache config: $e');
    }
  }
}
