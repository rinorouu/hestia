import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../models/storage_status.dart';
import 'auth_service.dart';
import 'server_config_service.dart';

/// Memantau `GET /storage/status` (ketersediaan HDD eksternal) supaya app bisa
/// menampilkan banner "media penyimpanan tidak tersedia" & menonaktifkan upload.
class StorageStatusService extends ChangeNotifier {
  StorageStatusService({required this.serverConfig, required this.authService}) {
    _apiClient = ApiClient(serverConfig: serverConfig, tokenGetter: () => authService.token);
  }

  final ServerConfigService serverConfig;
  final AuthService authService;
  late final ApiClient _apiClient;

  StorageStatus? _status;
  bool _loading = false;

  StorageStatus? get status => _status;
  bool get loading => _loading;

  /// Optimistis `true` sampai pengecekan pertama selesai, supaya UI tidak
  /// menampilkan banner sebelum data benar-benar diketahui.
  bool get isAvailable => _status?.available ?? true;

  Future<void> refresh() async {
    if (!authService.isAuthenticated) return;
    _loading = true;
    notifyListeners();
    try {
      final res = await _apiClient.dio.get('/storage/status');
      _status = StorageStatus.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      // Biarkan status lama bila fetch gagal (mis. jaringan putus sesaat).
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
