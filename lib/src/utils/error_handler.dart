import 'package:dio/dio.dart';

class AppErrorHandler {
  static String format(dynamic error) {
    if (error is String) return error;

    // Parse Dio HTTP errors — the most common in this app
    if (error is DioException) {
      final response = error.response;
      if (response != null) {
        final data = response.data;

        // 422 Unprocessable Entity — Laravel validation errors
        // Shape: { message: '...', errors: { field: ['msg'] } }
        if (response.statusCode == 422 && data is Map) {
          final errors = data['errors'] as Map?;
          if (errors != null && errors.isNotEmpty) {
            // Return the first field's first message
            final firstField = errors.values.first;
            if (firstField is List && firstField.isNotEmpty) {
              return firstField.first.toString();
            }
          }
          // Fall back to the top-level message key
          if (data['message'] != null) {
            return data['message'].toString();
          }
        }

        // Generic backend error — Laravel ApiResponse::error shape
        // { message: '...' } or { data: null, message: '...' }
        if (data is Map) {
          if (data['message'] != null) return data['message'].toString();
        }

        // Connection / HTTP-level errors
        return switch (response.statusCode) {
          401 => 'Unauthorised. Please sign in again.',
          403 => 'Access denied.',
          404 => 'Resource not found.',
          500 => 'Server error. Please try again later.',
          _ => 'Request failed (${response.statusCode}).',
        };
      }

      // Network-level errors (no response)
      return switch (error.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.sendTimeout =>
          'Connection timed out. Check your internet.',
        DioExceptionType.connectionError =>
          'Could not reach the server. Check your connection.',
        _ => error.message ?? 'Network error.',
      };
    }

    try {
      if (error?.message != null) return error.message.toString();
      if (error?.toString() != null) return error.toString();
    } catch (_) {}

    return 'An unexpected error occurred.';
  }
}
