/// Mengikuti `toPublicFile` / `toDetailedFile` di server/src/utils/serialize.js.
/// Field detail (`rel_path`, `checksum`, `taken_at`) nullable karena hanya
/// terisi saat diambil dari `GET /files/:id`, tidak dari list `GET /files`.
class FileItem {
  const FileItem({
    required this.id,
    required this.filename,
    required this.sizeBytes,
    required this.mimeType,
    required this.thumbUrl,
    required this.uploadedAt,
    this.relPath,
    this.checksum,
    this.takenAt,
  });

  final int id;
  final String filename;
  final int sizeBytes;
  final String mimeType;
  final String? thumbUrl;
  final DateTime uploadedAt;
  final String? relPath;
  final String? checksum;
  final DateTime? takenAt;

  bool get isImage => mimeType.startsWith('image/');
  bool get isVideo => mimeType.startsWith('video/');

  factory FileItem.fromJson(Map<String, dynamic> json) {
    return FileItem(
      id: json['id'] as int,
      filename: json['filename'] as String,
      sizeBytes: json['size_bytes'] as int,
      mimeType: json['mime_type'] as String? ?? 'application/octet-stream',
      thumbUrl: json['thumb_url'] as String?,
      uploadedAt: DateTime.parse(json['uploaded_at'] as String),
      relPath: json['rel_path'] as String?,
      checksum: json['checksum'] as String?,
      takenAt: json['taken_at'] != null ? DateTime.tryParse(json['taken_at'] as String) : null,
    );
  }
}
