import 'package:dio/dio.dart';

/// Error terstruktur dari API Hestia, dibangun dari format standar
/// server `{ "error": { "code", "message" } }` (lihat server/src/utils/errors.js).
class ApiException implements Exception {
  const ApiException({required this.code, required this.message, this.statusCode});

  final int? statusCode;
  final String code;
  final String message;

  factory ApiException.fromDioError(DioException e) {
    final res = e.response;
    final data = res?.data;
    if (data is Map && data['error'] is Map) {
      final err = data['error'] as Map;
      return ApiException(
        statusCode: res?.statusCode,
        code: (err['code'] as String?) ?? 'UNKNOWN_ERROR',
        message: (err['message'] as String?) ?? 'Terjadi kesalahan.',
      );
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(code: 'TIMEOUT', message: 'Koneksi ke server timeout.');
      case DioExceptionType.connectionError:
        return const ApiException(
          code: 'CONNECTION_ERROR',
          message: 'Tidak dapat terhubung ke server. Periksa alamat server & jaringan.',
        );
      default:
        return ApiException(
          statusCode: res?.statusCode,
          code: 'UNKNOWN_ERROR',
          message: e.message ?? 'Terjadi kesalahan tak terduga.',
        );
    }
  }

  @override
  String toString() => message;
}
