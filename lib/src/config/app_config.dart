import '../imports/core_imports.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/secure_storage_service.dart';

class AppConfig {
  AppConfig._();
  static late final Dio dio;

  static String get baseUrl => _getBaseUrl();

  /// The app key for this build. Read from .env so it can be overridden via
  /// `--dart-define=APP_KEY=xxx` in CI/CD without touching source code.
  static String get appKey {
    // dart-define takes priority; falls back to .env
    const dartDefineKey = String.fromEnvironment('APP_KEY');
    if (dartDefineKey.isNotEmpty) return dartDefineKey;
    return dotenv.get('APP_KEY', fallback: '');
  }

  static Future<void> init() async {
    dio = Dio(
      BaseOptions(
        baseUrl: _getBaseUrl(),
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Only attach sensitive headers for internal API calls
          final isInternal = !options.path.startsWith('http') ||
              options.path.startsWith(AppConfig.baseUrl);

          if (isInternal) {
            // 1. Attach X-App-Key for tenant resolution (required on every call)
            final key = AppConfig.appKey;
            if (key.isNotEmpty) {
              options.headers['X-App-Key'] = key;
            }

            // 2. Attach Bearer token if the user is logged in
            final tokenResult =
                await SecureStorageService.instance.read('auth_token');
            tokenResult.fold(
              (_) => null,
              (token) {
                if (token != null) {
                  options.headers['Authorization'] = 'Bearer $token';
                }
              },
            );
          }

          AppLogger.info(
              '🌐 [DIO] REQUEST[${options.method}] => PATH: ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          AppLogger.info(
              '✅ [DIO] RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          AppLogger.error(
              '❌ [DIO] ERROR[${e.response?.statusCode}] => PATH: ${e.requestOptions.path}');
          return handler.next(e);
        },
      ),
    );
  }

  static String _getBaseUrl() {
    return dotenv.get('API_BASE_URL',
        fallback: 'http://127.0.0.1:8000/api/v1');
  }
}
