import 'package:circa_flow_main/src/imports/core_imports.dart';
import 'package:dio/dio.dart';
import '../config/app_config.dart';

/// A generic API service that wraps Dio requests with standard error handling and task running.
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  Dio get _dio => AppConfig.dio;

  /// Performs a GET request.
  FutureEither<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return runTask(() async {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data as T;
    }, requiresNetwork: true);
  }

  /// Performs a POST request.
  FutureEither<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return runTask(() async {
      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data as T;
    }, requiresNetwork: true);
  }

  /// Performs a PUT request.
  FutureEither<T> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return runTask(() async {
      final response = await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data as T;
    }, requiresNetwork: true);
  }

  /// Performs a DELETE request.
  FutureEither<T> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return runTask(() async {
      final response = await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data as T;
    }, requiresNetwork: true);
  }

  /// Performs a PATCH request.
  FutureEither<T> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return runTask(() async {
      final response = await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data as T;
    }, requiresNetwork: true);
  }

  /// Uploads a file using multipart/form-data.
  FutureEither<T> uploadFile<T>(
    String path, {
    required String filePath,
    required String fieldName,
    Map<String, dynamic>? extraData,
  }) async {
    return runTask(() async {
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(filePath),
        if (extraData != null) ...extraData,
      });

      final response = await _dio.post<T>(path, data: formData);
      return response.data as T;
    }, requiresNetwork: true);
  }

  /// Uploads multiple files using multipart/form-data.
  FutureEither<T> uploadFiles<T>(
    String path, {
    required List<String> filePaths,
    required String fieldName,
    Map<String, dynamic>? extraData,
  }) async {
    return runTask(() async {
      final multipartFiles = await Future.wait(
        filePaths.map((fp) => MultipartFile.fromFile(fp)),
      );

      final Map<String, dynamic> formDataMap = {
        fieldName: multipartFiles,
      };

      if (extraData != null) {
        formDataMap.addAll(extraData);
      }

      final formData = FormData.fromMap(formDataMap);

      final response = await _dio.post<T>(path, data: formData);
      return response.data as T;
    }, requiresNetwork: true);
  }
}
