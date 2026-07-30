import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Menyimpan & memvalidasi alamat server Hestia (mis. `http://192.168.1.10:3000`).
/// Bukan data rahasia, jadi cukup `shared_preferences` (bandingkan dengan token JWT
/// yang disimpan di secure storage lewat AuthService).
class ServerConfigService extends ChangeNotifier {
  static const _prefKey = 'server_base_url';

  SharedPreferences? _prefs;
  String? _baseUrl;
  bool _loaded = false;

  String? get baseUrl => _baseUrl;
  bool get isConfigured => _baseUrl != null && _baseUrl!.isNotEmpty;
  bool get loaded => _loaded;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    _baseUrl = _prefs!.getString(_prefKey);
    _loaded = true;
    notifyListeners();
  }

  Future<void> setBaseUrl(String url) async {
    final normalized = normalize(url);
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(_prefKey, normalized);
    _baseUrl = normalized;
    notifyListeners();
  }

  Future<void> clear() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.remove(_prefKey);
    _baseUrl = null;
    notifyListeners();
  }

  static String normalize(String url) {
    var value = url.trim();
    if (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    return value;
  }

  /// Tes koneksi ke `GET /api/health` tanpa bergantung pada baseUrl yang sudah
  /// tersimpan — dipakai di layar Server Setup sebelum alamat disimpan.
  Future<bool> testConnection(String url) async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
      ),
    );
    try {
      final res = await dio.get('${normalize(url)}/api/health');
      final data = res.data;
      return res.statusCode == 200 && data is Map && data['status'] == 'ok';
    } catch (_) {
      return false;
    }
  }
}
