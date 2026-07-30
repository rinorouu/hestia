class HistoryItem {
  const HistoryItem({
    required this.id,
    required this.fileId,
    required this.status,
    required this.message,
    required this.createdAt,
  });

  final int id;
  final int? fileId;
  final String status;
  final String? message;
  final DateTime createdAt;

  bool get isSuccess => status == 'success';

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id'] as int,
      fileId: json['file_id'] as int?,
      status: json['status'] as String,
      message: json['message'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
