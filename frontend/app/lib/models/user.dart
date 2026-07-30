class User {
  const User({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
  });

  final int id;
  final String email;
  final String? displayName;
  final String role;

  String get nameOrEmail => (displayName != null && displayName!.trim().isNotEmpty) ? displayName! : email;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      role: json['role'] as String? ?? 'user',
    );
  }
}
