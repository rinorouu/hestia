import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/history_item.dart';
import 'auth_service.dart';
import 'server_config_service.dart';

/// Riwayat upload (`GET /history`) — docs/API_SPEC.md bagian History.
class HistoryService {
  HistoryService({required this.serverConfig, required this.authService}) {
    _apiClient = ApiClient(serverConfig: serverConfig, tokenGetter: () => authService.token);
  }

  final ServerConfigService serverConfig;
  final AuthService authService;
  late final ApiClient _apiClient;

  Future<List<HistoryItem>> list({int limit = 100}) async {
    try {
      final res = await _apiClient.dio.get('/history', queryParameters: {'limit': limit});
      final items = (res.data as Map<String, dynamic>)['items'] as List;
      return items.map((e) => HistoryItem.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
