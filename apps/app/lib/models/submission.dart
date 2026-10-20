import 'package:edtech_app/models/attachment.dart';

class Submission {
  const Submission({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.status,
    required this.submittedAt,
    required this.attachments,
    required this.grade,
    required this.effortScore,
  });

  final String id;
  final String assignmentId;
  final String studentId;
  final String status;
  final DateTime? submittedAt;
  final List<Attachment> attachments;
  final num? grade;
  final num? effortScore;

  factory Submission.fromJson(Map<String, dynamic> json) {
    return Submission(
      id: json['id'] as String,
      assignmentId: json['assignmentId'] as String,
      studentId: json['studentId'] as String,
      status: json['status'] as String,
      submittedAt: json['submittedAt'] == null
          ? null
          : DateTime.tryParse(json['submittedAt'] as String? ?? ''),
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((item) => Attachment.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      grade: json['grade'] as num?,
      effortScore: json['effortScore'] as num?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'assignmentId': assignmentId,
      'studentId': studentId,
      'status': status,
      'submittedAt': submittedAt?.toIso8601String(),
      'attachments': attachments.map((item) => item.toJson()).toList(),
      'grade': grade,
      'effortScore': effortScore,
    };
  }

  bool get isLate => status == 'late';
  bool get isPending => status == 'pending';
}
