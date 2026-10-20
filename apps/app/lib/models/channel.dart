class Channel {
  const Channel({
    required this.id,
    required this.courseId,
    required this.name,
    required this.kind,
    required this.memberIds,
  });

  final String id;
  final String courseId;
  final String name;
  final String kind;
  final List<String> memberIds;

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      id: json['id'] as String,
      courseId: json['courseId'] as String,
      name: json['name'] as String,
      kind: json['kind'] as String,
      memberIds: List<String>.from(json['memberIds'] as List<dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'courseId': courseId,
      'name': name,
      'kind': kind,
      'memberIds': memberIds,
    };
  }

  bool get isAnnouncement => kind == 'announcement';
}
