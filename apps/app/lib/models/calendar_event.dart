class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.courseId,
    required this.title,
    required this.kind,
    required this.startsAt,
    required this.endsAt,
    this.departmentId,
  });

  final String id;
  final String? courseId;
  final String? departmentId;
  final String title;
  final String kind;
  final DateTime startsAt;
  final DateTime? endsAt;

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] as String,
      courseId: json['courseId'] as String?,
      departmentId: json['departmentId'] as String?,
      title: json['title'] as String,
      kind: json['kind'] as String,
      startsAt: DateTime.tryParse(json['startsAt'] as String? ?? '') ?? DateTime.now(),
      endsAt: json['endsAt'] == null
          ? null
          : DateTime.tryParse(json['endsAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'courseId': courseId,
      'departmentId': departmentId,
      'title': title,
      'kind': kind,
      'startsAt': startsAt.toIso8601String(),
      'endsAt': endsAt?.toIso8601String(),
    };
  }
}
