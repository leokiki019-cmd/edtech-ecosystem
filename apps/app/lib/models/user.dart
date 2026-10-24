class User {
  const User({
    required this.id,
    required this.displayName,
    required this.email,
    required this.phone,
    required this.role,
    required this.courseIds,
    required this.createdAt,
    this.isPhoneVerified,
  });

  final String id;
  final String displayName;
  final String email;
  final String phone;
  final String role;
  final List<String> courseIds;
  final DateTime createdAt;
  final bool? isPhoneVerified;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String? ?? '',
      role: json['role'] as String,
      courseIds: List<String>.from(json['courseIds'] as List<dynamic>),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      isPhoneVerified: json['is_phone_verified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'displayName': displayName,
      'email': email,
      'phone': phone,
      'role': role,
      'courseIds': courseIds,
      'isPhoneVerified': isPhoneVerified,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool get isStudent => role == 'student';
  bool get isTeacher => role == 'teacher';
  bool get isAdmin => role == 'admin';
}
