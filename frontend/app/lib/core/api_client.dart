import 'package:dio/dio.dart';

import '../services/server_config_service.dart';

/// Callback yang mengembalikan token JWT saat ini (atau null bila belum login).
/// Dipakai lewat closure agar [ApiClient] tidak perlu bergantung langsung ke AuthService.
typedef TokenGetter = String? Function();

/// Pembungkus Dio tipis: base URL diambil dinamis dari [ServerConfigService]
/// (bisa berubah kalau user mengganti alamat server di Pengaturan), dan header
/// `Authorization` disisipkan otomatis lewat [TokenGetter].
class ApiClient {
  ApiClient({required this.serverConfig, required this.tokenGetter})
      : dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(minutes: 10),
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final base = serverConfig.baseUrl;
          if (base != null && base.isNotEmpty && !options.path.startsWith('http')) {
            options.baseUrl = '$base/api';
          }
          final token = tokenGetter();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio dio;
  final ServerConfigService serverConfig;
  final TokenGetter tokenGetter;

  /// Header auth siap pakai untuk request di luar Dio ini (mis. CachedNetworkImage).
  Map<String, String> get authHeaders {
    final token = tokenGetter();
    return (token != null && token.isNotEmpty) ? {'Authorization': 'Bearer $token'} : const {};
  }

  /// Ubah path beserta prefix `/api` (mis. dari `thumb_url`/`download` server)
  /// menjadi URL absolut ke server yang sedang aktif.
  String resolveUrl(String pathWithApiPrefix) {
    final base = serverConfig.baseUrl ?? '';
    return '$base$pathWithApiPrefix';
  }
}
