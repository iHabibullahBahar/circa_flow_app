import '../imports/core_imports.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/secure_storage_service.dart';

class AppConfig {
  AppConfig._();
  static late final Dio dio;

  static String get baseUrl => _getBaseUrl();

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
          // Add Token if exists
          final tokenResult = await SecureStorageService.instance.read('auth_token');
          tokenResult.fold(
            (_) => null,
            (token) {
              if (token != null) {
                options.headers['Authorization'] = 'Bearer $token';
              }
            },
          );

          AppLogger.info('🌐 [DIO] REQUEST[${options.method}] => PATH: ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          AppLogger.info('✅ [DIO] RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          AppLogger.error('❌ [DIO] ERROR[${e.response?.statusCode}] => PATH: ${e.requestOptions.path}');
          return handler.next(e);
        },
      ),
    );

  }

  static String _getBaseUrl() {
    return dotenv.get('API_BASE_URL', fallback: 'https://www.circaflow.co.uk/api/v1');
  }
}
