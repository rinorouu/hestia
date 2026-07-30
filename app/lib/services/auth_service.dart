import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/user.dart';
import 'server_config_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// Autentikasi: register/login/me, menyimpan token JWT di secure storage
/// (sesuai docs/SECURITY.md — token tidak boleh plaintext), dan expose status
/// login untuk routing (Splash -> Login/Home).
class AuthService extends ChangeNotifier {
  AuthService({required this.serverConfig}) {
    _apiClient = ApiClient(serverConfig: serverConfig, tokenGetter: () => _token);
  }

  final ServerConfigService serverConfig;
  late final ApiClient _apiClient;
  final _secureStorage = const FlutterSecureStorage();
  static const _tokenKey = 'auth_token';

  String? _token;
  User? _currentUser;
  AuthStatus _status = AuthStatus.unknown;

  String? get token => _token;
  User? get currentUser => _currentUser;
  AuthStatus get status => _status;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Dipanggil sekali saat splash: baca token tersimpan lalu validasi ke /auth/me.
  Future<void> restoreSession() async {
    _token = await _secureStorage.read(key: _tokenKey);
    if (_token == null || _token!.isEmpty) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      final res = await _apiClient.dio.get('/auth/me');
      _currentUser = User.fromJson(res.data as Map<String, dynamic>);
      _status = AuthStatus.authenticated;
    } catch (_) {
      _token = null;
      await _secureStorage.delete(key: _tokenKey);
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final res = await _apiClient.dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        if (displayName != null && displayName.trim().isNotEmpty) 'display_name': displayName.trim(),
      });
      await _applyAuthResult(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> login({required String email, required String password}) async {
    try {
      final res = await _apiClient.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      await _applyAuthResult(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> _applyAuthResult(Map<String, dynamic> data) async {
    _token = data['token'] as String;
    _currentUser = User.fromJson(data['user'] as Map<String, dynamic>);
    await _secureStorage.write(key: _tokenKey, value: _token);
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    await _secureStorage.delete(key: _tokenKey);
    notifyListeners();
  }
}
