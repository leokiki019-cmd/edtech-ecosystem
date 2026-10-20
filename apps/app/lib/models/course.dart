class Course {
  const Course({
    required this.id,
    required this.title,
    required this.code,
    required this.teacherId,
    required this.studentIds,
    required this.term,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String code;
  final String teacherId;
  final List<String> studentIds;
  final String term;
  final DateTime createdAt;

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as String,
      title: json['title'] as String,
      code: json['code'] as String,
      teacherId: json['teacherId'] as String,
      studentIds: List<String>.from(json['studentIds'] as List<dynamic>),
      term: json['term'] as String,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'code': code,
      'teacherId': teacherId,
      'studentIds': studentIds,
      'term': term,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
