class Assignment {
  const Assignment({
    required this.id,
    required this.courseId,
    required this.title,
    required this.brief,
    required this.dueAt,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String courseId;
  final String title;
  final String brief;
  final DateTime dueAt;
  final String status;
  final DateTime createdAt;

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'] as String,
      courseId: json['courseId'] as String,
      title: json['title'] as String,
      brief: json['brief'] as String,
      dueAt: DateTime.tryParse(json['dueAt'] as String? ?? '') ?? DateTime.now(),
      status: json['status'] as String,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'courseId': courseId,
      'title': title,
      'brief': brief,
      'dueAt': dueAt.toIso8601String(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool get isOpen => status == 'open';
  bool get isOverdue => DateTime.now().isAfter(dueAt);
}
