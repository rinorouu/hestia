class StorageStatus {
  const StorageStatus({
    required this.available,
    required this.reason,
    required this.totalBytes,
    required this.freeBytes,
  });

  final bool available;
  final String? reason;
  final int? totalBytes;
  final int? freeBytes;

  factory StorageStatus.fromJson(Map<String, dynamic> json) {
    return StorageStatus(
      available: json['available'] as bool,
      reason: json['reason'] as String?,
      totalBytes: json['total_bytes'] as int?,
      freeBytes: json['free_bytes'] as int?,
    );
  }
}
