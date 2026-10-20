class User {
  const User({
    required this.id,
    required this.displayName,
    required this.email,
    required this.role,
    required this.courseIds,
    required this.createdAt,
  });

  final String id;
  final String displayName;
  final String email;
  final String role;
  final List<String> courseIds;
  final DateTime createdAt;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      courseIds: List<String>.from(json['courseIds'] as List<dynamic>),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'displayName': displayName,
      'email': email,
      'role': role,
      'courseIds': courseIds,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool get isStudent => role == 'student';
  bool get isTeacher => role == 'teacher';
  bool get isAdmin => role == 'admin';
}
