class FolderItem {
  const FolderItem({required this.name, required this.path});

  final String name;
  final String path;

  factory FolderItem.fromJson(Map<String, dynamic> json) {
    return FolderItem(
      name: json['name'] as String,
      path: json['path'] as String,
    );
  }
}
