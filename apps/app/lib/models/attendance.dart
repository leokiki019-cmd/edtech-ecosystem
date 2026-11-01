import 'package:edtech_app/models/user.dart';

class AttendanceRecord {
  final String id;
  final String courseId;
  final String studentId;
  final String date; // YYYY-MM-DD
  final String status; // present, absent, late, excused
  final String markedBy;
  final String notes;
  final String createdAt;

  AttendanceRecord({
    required this.id,
    required this.courseId,
    required this.studentId,
    required this.date,
    required this.status,
    required this.markedBy,
    required this.notes,
    required this.createdAt,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] as String,
      courseId: json['courseId'] as String,
      studentId: json['studentId'] as String,
      date: json['date'] as String,
      status: json['status'] as String,
      markedBy: json['markedBy'] as String,
      notes: json['notes'] as String? ?? '',
      createdAt: json['createdAt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'studentId': studentId,
      'date': date,
      'status': status,
      'markedBy': markedBy,
      'notes': notes,
      'createdAt': createdAt,
    };
  }
}

class TeacherNote {
  final String id;
  final String courseId;
  final String bookName;
  final String courseCode;
  final String title;
  final String content;
  final String authorId;
  final String createdAt;
  final String updatedAt;

  TeacherNote({
    required this.id,
    required this.courseId,
    required this.bookName,
    required this.courseCode,
    required this.title,
    required this.content,
    required this.authorId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TeacherNote.fromJson(Map<String, dynamic> json) {
    return TeacherNote(
      id: json['id'] as String,
      courseId: json['courseId'] as String,
      bookName: json['bookName'] as String,
      courseCode: json['courseCode'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      authorId: json['authorId'] as String,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'bookName': bookName,
      'courseCode': courseCode,
      'title': title,
      'content': content,
      'authorId': authorId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class StudentDepartment {
  final String id;
  final String studentId;
  final String departmentId;
  final String enrolledAt;
  final String enrolledBy;

  StudentDepartment({
    required this.id,
    required this.studentId,
    required this.departmentId,
    required this.enrolledAt,
    required this.enrolledBy,
  });

  factory StudentDepartment.fromJson(Map<String, dynamic> json) {
    return StudentDepartment(
      id: json['id'] as String,
      studentId: json['studentId'] as String,
      departmentId: json['departmentId'] as String,
      enrolledAt: json['enrolledAt'] as String,
      enrolledBy: json['enrolledBy'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'departmentId': departmentId,
      'enrolledAt': enrolledAt,
      'enrolledBy': enrolledBy,
    };
  }
}

class StudentImportRow {
  final String name;
  final String rollNumber;
  final String contact;
  final String? courseId;
  final String? departmentId;

  StudentImportRow({
    required this.name,
    required this.rollNumber,
    required this.contact,
    this.courseId,
    this.departmentId,
  });
}

class StudentImportResult {
  final int imported;
  final List<Map<String, dynamic>> errors;
  final List<Map<String, dynamic>> students;

  StudentImportResult({
    required this.imported,
    required this.errors,
    required this.students,
  });

  factory StudentImportResult.fromJson(Map<String, dynamic> json) {
    return StudentImportResult(
      imported: json['imported'] as int,
      errors: (json['errors'] as List? ?? []).cast<Map<String, dynamic>>(),
      students: (json['students'] as List? ?? []).cast<Map<String, dynamic>>(),
    );
  }
}
