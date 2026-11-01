class Department {
  final String id;
  final String collegeId;
  final String name;
  final String code;
  final String category;
  final int durationMonths;
  final String createdAt;

  Department({
    required this.id,
    required this.collegeId,
    required this.name,
    required this.code,
    required this.category,
    required this.durationMonths,
    required this.createdAt,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'] as String,
      collegeId: json['collegeId'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      category: json['category'] as String,
      durationMonths: json['durationMonths'] as int,
      createdAt: json['createdAt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'collegeId': collegeId,
      'name': name,
      'code': code,
      'category': category,
      'durationMonths': durationMonths,
      'createdAt': createdAt,
    };
  }
}
