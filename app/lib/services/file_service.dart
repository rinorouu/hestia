import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/file_item.dart';
import '../models/folder_item.dart';
import 'auth_service.dart';
import 'server_config_service.dart';

class BrowseResult {
  const BrowseResult({
    required this.path,
    required this.folders,
    required this.files,
    required this.page,
    required this.total,
  });

  final String path;
  final List<FolderItem> folders;
  final List<FileItem> files;
  final int page;
  final int total;

  factory BrowseResult.fromJson(Map<String, dynamic> json) {
    return BrowseResult(
      path: json['path'] as String,
      folders: (json['folders'] as List)
          .map((e) => FolderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      files: (json['files'] as List).map((e) => FileItem.fromJson(e as Map<String, dynamic>)).toList(),
      page: json['page'] as int,
      total: json['total'] as int,
    );
  }
}

class UploadFailure {
  const UploadFailure({required this.filename, required this.reason});

  final String filename;
  final String reason;

  factory UploadFailure.fromJson(Map<String, dynamic> json) {
    return UploadFailure(
      filename: json['filename']?.toString() ?? 'berkas',
      reason: json['reason']?.toString() ?? 'UNKNOWN',
    );
  }
}

class UploadOutcome {
  const UploadOutcome({required this.uploaded, required this.failed});

  final List<FileItem> uploaded;
  final List<UploadFailure> failed;
}

/// Browse, upload, download, detail, dan hapus file — sesuai
/// docs/API_SPEC.md bagian Files, diverifikasi lewat server/src/routes/files.js.
class FileService {
  FileService({required this.serverConfig, required this.authService}) {
    _apiClient = ApiClient(serverConfig: serverConfig, tokenGetter: () => authService.token);
  }

  final ServerConfigService serverConfig;
  final AuthService authService;
  late final ApiClient _apiClient;

  String? thumbnailUrl(FileItem file) {
    final url = file.thumbUrl;
    return url != null ? _apiClient.resolveUrl(url) : null;
  }

  String downloadUrl(int id) => _apiClient.resolveUrl('/api/download/$id');

  Map<String, String> get authHeaders => _apiClient.authHeaders;

  Future<BrowseResult> browse({
    String path = '/',
    int page = 1,
    int limit = 50,
    String sort = 'uploaded_at',
  }) async {
    try {
      final res = await _apiClient.dio.get('/files', queryParameters: {
        'path': path,
        'page': page,
        'limit': limit,
        'sort': sort,
      });
      return BrowseResult.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<FileItem> detail(int id) async {
    try {
      final res = await _apiClient.dio.get('/files/$id');
      return FileItem.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Upload satu atau banyak file sekaligus dalam satu request multipart
  /// (sesuai server: field `files` bisa berulang). [onProgress] melaporkan
  /// progres agregat seluruh batch, bukan per-file, karena semuanya dikirim
  /// dalam satu body multipart.
  Future<UploadOutcome> upload({
    required List<PlatformFile> files,
    String? path,
    ProgressCallback? onProgress,
  }) async {
    try {
      final formData = FormData();
      if (path != null && path.isNotEmpty) {
        formData.fields.add(MapEntry('path', path));
      }
      for (final f in files) {
        if (f.path == null) continue;
        formData.files.add(
          MapEntry('files', await MultipartFile.fromFile(f.path!, filename: f.name)),
        );
      }
      final res = await _apiClient.dio.post('/upload', data: formData, onSendProgress: onProgress);
      final data = res.data as Map<String, dynamic>;
      final uploaded =
          (data['uploaded'] as List).map((e) => FileItem.fromJson(e as Map<String, dynamic>)).toList();
      final failed =
          (data['failed'] as List).map((e) => UploadFailure.fromJson(e as Map<String, dynamic>)).toList();
      return UploadOutcome(uploaded: uploaded, failed: failed);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Unduh file ke cache app lokal (bukan langsung ke folder publik) untuk
  /// menghindari kerumitan izin storage yang berbeda tiap versi Android —
  /// pemanggil lalu menawarkan "Buka" / "Simpan" lewat share sheet OS.
  Future<File> download(FileItem file, {ProgressCallback? onProgress}) async {
    try {
      final dir = await path_provider.getTemporaryDirectory();
      final savePath = '${dir.path}/${file.filename}';
      await _apiClient.dio.download(
        _apiClient.resolveUrl('/api/download/${file.id}'),
        savePath,
        onReceiveProgress: onProgress,
      );
      return File(savePath);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deleteFile(int id) async {
    try {
      await _apiClient.dio.delete('/files/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
