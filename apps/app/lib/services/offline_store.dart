import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Local, persistent data store used when [AppConfig.offlineMode] is true.
///
/// It mirrors the shape of the JSON returned by the Fastify API so the rest of
/// the app does not need to know whether it is talking to a server or to this
/// on-device demo store. Data is persisted with shared_preferences and survives
/// app restarts.
class OfflineStore {
  OfflineStore._();
  static final OfflineStore instance = OfflineStore._();

  static const _studentsKey = 'offline_students_v1';
  static const _departmentsKey = 'offline_departments_v1';
  static const _enrollmentsKey = 'offline_enrollments_v1';
  static const _attendanceKey = 'offline_attendance_v1';
  static const _notesKey = 'offline_notes_v1';
  static const _submissionsKey = 'offline_submissions_v1';
  static const _messagesKey = 'offline_messages_v1';
  static const _calendarKey = 'offline_calendar_v1';

  SharedPreferences? _prefs;
  bool _loaded = false;

  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _enrollments = [];
  List<Map<String, dynamic>> _attendance = [];
  List<Map<String, dynamic>> _notes = [];
  List<Map<String, dynamic>> _submissions = [];
  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> _calendar = [];

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _prefs = await SharedPreferences.getInstance();
    _students = _read(_studentsKey);
    _departments = _read(_departmentsKey);
    _enrollments = _read(_enrollmentsKey);
    _attendance = _read(_attendanceKey);
    _notes = _read(_notesKey);
    _submissions = _read(_submissionsKey);
    _messages = _read(_messagesKey);
    _calendar = _read(_calendarKey);
    if (_students.isEmpty && _departments.isEmpty) {
      _seed();
      await _persistAll();
    } else if (_calendar.isEmpty) {
      _seedCalendar();
      await _persist(_calendarKey, _calendar);
    }
    _loaded = true;
  }

  List<Map<String, dynamic>> _read(String key) {
    final raw = _prefs?.getString(key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _persist(String key, List<Map<String, dynamic>> rows) async {
    await _prefs?.setString(key, jsonEncode(rows));
  }

  Future<void> _persistAll() async {
    await _persist(_studentsKey, _students);
    await _persist(_departmentsKey, _departments);
    await _persist(_enrollmentsKey, _enrollments);
    await _persist(_attendanceKey, _attendance);
    await _persist(_notesKey, _notes);
    await _persist(_submissionsKey, _submissions);
    await _persist(_messagesKey, _messages);
    await _persist(_calendarKey, _calendar);
  }

  String _id(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}';

  String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  void _seed() {
    const createdAt = '2026-08-15T00:00:00.000Z';
    _students = [
      {
        'id': 'u-student-1',
        'displayName': 'Alex Rivera',
        'email': 'alex.rivera@example.edu',
        'phone': '+15550001002',
        'role': 'student',
        'courseIds': ['c-cs301', 'c-cs210', 'c-des150'],
        'rollNumber': 'CIT-2026-001',
        'isPhoneVerified': true,
        'createdAt': createdAt,
      },
      {
        'id': 'u-student-2',
        'displayName': 'Priya Nair',
        'email': 'priya.nair@example.edu',
        'phone': '+15550001003',
        'role': 'student',
        'courseIds': ['c-cs301'],
        'rollNumber': 'CIT-2026-002',
        'isPhoneVerified': true,
        'createdAt': createdAt,
      },
      {
        'id': 'u-student-3',
        'displayName': 'Jordan Lee',
        'email': 'jordan.lee@example.edu',
        'phone': '+15550001004',
        'role': 'student',
        'courseIds': ['c-cs301', 'c-des150'],
        'rollNumber': 'CIT-2026-003',
        'isPhoneVerified': true,
        'createdAt': createdAt,
      },
      {
        'id': 'u-student-4',
        'displayName': 'Maya Khan',
        'email': 'maya.khan@example.edu',
        'phone': '+15550001006',
        'role': 'student',
        'courseIds': ['c-cs210'],
        'rollNumber': 'CIT-2026-004',
        'isPhoneVerified': true,
        'createdAt': createdAt,
      },
      {
        'id': 'u-student-5',
        'displayName': 'Noah Ahmed',
        'email': 'noah.ahmed@example.edu',
        'phone': '+15550001007',
        'role': 'student',
        'courseIds': ['c-des150'],
        'rollNumber': 'CIT-2026-005',
        'isPhoneVerified': true,
        'createdAt': createdAt,
      },
    ];

    _departments = [
      {
        'id': 'dept-cit',
        'collegeId': 'col-cttc',
        'name': 'Computer Info Tech.',
        'code': 'CIT',
        'category': '3 Years',
        'durationMonths': 36,
        'createdAt': '2026-01-01T00:00:00.000Z',
      },
      {
        'id': 'dept-eee',
        'collegeId': 'col-cttc',
        'name': 'Electrical Technology',
        'code': 'EEE',
        'category': '3 Years',
        'durationMonths': 36,
        'createdAt': '2026-01-01T00:00:00.000Z',
      },
      {
        'id': 'dept-mec',
        'collegeId': 'col-cttc',
        'name': 'Mechanical',
        'code': 'MEC',
        'category': '3 Years',
        'durationMonths': 36,
        'createdAt': '2026-01-01T00:00:00.000Z',
      },
      {
        'id': 'dept-cnc',
        'collegeId': 'col-cttc',
        'name': 'CNC Programmer',
        'code': 'CNC',
        'category': '6 Months',
        'durationMonths': 6,
        'createdAt': '2026-01-01T00:00:00.000Z',
      },
      {
        'id': 'dept-mlt',
        'collegeId': 'col-cttc',
        'name': 'Medical Laboratory Technology',
        'code': 'MLT',
        'category': '2 Years Paramedical',
        'durationMonths': 24,
        'createdAt': '2026-01-01T00:00:00.000Z',
      },
      {
        'id': 'dept-ott',
        'collegeId': 'col-cttc',
        'name': 'Operation Theatre Technology',
        'code': 'OTT',
        'category': '2 Years Paramedical',
        'durationMonths': 24,
        'createdAt': '2026-01-01T00:00:00.000Z',
      },
    ];

    _enrollments = [
      {
        'id': _id('enr'),
        'studentId': 'u-student-1',
        'departmentId': 'dept-cit',
        'enrolledAt': createdAt,
        'enrolledBy': 'u-admin-1',
      },
      {
        'id': _id('enr'),
        'studentId': 'u-student-2',
        'departmentId': 'dept-cit',
        'enrolledAt': createdAt,
        'enrolledBy': 'u-admin-1',
      },
      {
        'id': _id('enr'),
        'studentId': 'u-student-4',
        'departmentId': 'dept-eee',
        'enrolledAt': createdAt,
        'enrolledBy': 'u-admin-1',
      },
    ];

    _attendance = [
      {
        'id': _id('att'),
        'courseId': 'c-cs301',
        'studentId': 'u-student-1',
        'date': _today(),
        'status': 'present',
        'markedBy': 'u-teacher-1',
        'notes': '',
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'id': _id('att'),
        'courseId': 'c-cs301',
        'studentId': 'u-student-2',
        'date': _today(),
        'status': 'present',
        'markedBy': 'u-teacher-1',
        'notes': '',
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'id': _id('att'),
        'courseId': 'c-cs301',
        'studentId': 'u-student-3',
        'date': _today(),
        'status': 'absent',
        'markedBy': 'u-teacher-1',
        'notes': 'Sick leave',
        'createdAt': DateTime.now().toIso8601String(),
      },
    ];

    _notes = [
      {
        'id': 'note-1',
        'courseId': 'c-cs301',
        'bookName': 'Interaction Design: Beyond Human-Computer Interaction',
        'courseCode': 'CIT-301',
        'title': 'Week 1 - Foundations of HCI',
        'content':
            'Covers usability goals, user experience goals, and the difference between interaction design and human-computer interaction.',
        'authorId': 'u-teacher-1',
        'createdAt': '2026-09-02T08:00:00.000Z',
        'updatedAt': '2026-09-02T08:00:00.000Z',
      },
      {
        'id': 'note-2',
        'courseId': 'c-cs210',
        'bookName': 'Data Structures and Algorithm Analysis',
        'courseCode': 'CIT-302',
        'title': 'Binary Search Trees',
        'content':
            'Insert, search, delete, and traversal algorithms for binary search trees with complexity analysis.',
        'authorId': 'u-teacher-2',
        'createdAt': '2026-09-05T08:00:00.000Z',
        'updatedAt': '2026-09-05T08:00:00.000Z',
      },
    ];

    _submissions = [];
    _messages = [
      {
        'id': 'm-1',
        'channelId': 'ch-general',
        'authorId': 'u-teacher-1',
        'body': 'Welcome to the course!',
        'sentAt': DateTime.now()
            .subtract(const Duration(hours: 2))
            .toIso8601String(),
      },
      {
        'id': 'm-2',
        'channelId': 'ch-general',
        'authorId': 'u-student-1',
        'body': 'Thanks, excited to start.',
        'sentAt': DateTime.now()
            .subtract(const Duration(hours: 1))
            .toIso8601String(),
      },
    ];

    _seedCalendar();
  }

  void _seedCalendar() {
    String day(int offset) => DateTime.now()
        .add(Duration(days: offset))
        .toIso8601String();

    _calendar = [
      {
        'id': 'ev-cit-orientation',
        'courseId': null,
        'departmentId': 'dept-cit',
        'title': 'CIT Orientation',
        'kind': 'institution',
        'startsAt': day(1),
        'endsAt': DateTime.now()
            .add(const Duration(days: 1, hours: 2))
            .toIso8601String(),
      },
      {
        'id': 'ev-eee-safety',
        'courseId': null,
        'departmentId': 'dept-eee',
        'title': 'EEE Safety Workshop',
        'kind': 'class',
        'startsAt': day(2),
        'endsAt': DateTime.now()
            .add(const Duration(days: 2, hours: 3))
            .toIso8601String(),
      },
      {
        'id': 'ev-arc-studio',
        'courseId': null,
        'departmentId': 'dept-arc',
        'title': 'Architecture Studio Review',
        'kind': 'class',
        'startsAt': day(4),
        'endsAt': null,
      },
      {
        'id': 'ev1',
        'courseId': 'c-cs301',
        'departmentId': 'dept-cit',
        'title': 'HCI Quiz 1',
        'kind': 'quiz',
        'startsAt': day(3),
        'endsAt': DateTime.now()
            .add(const Duration(days: 3, hours: 1))
            .toIso8601String(),
      },
      {
        'id': 'ev2',
        'courseId': 'c-cs301',
        'departmentId': 'dept-cit',
        'title': 'Heuristic Evaluation due',
        'kind': 'assignment',
        'startsAt': day(5),
        'endsAt': null,
      },
      {
        'id': 'ev3',
        'courseId': 'c-cs210',
        'departmentId': 'dept-cit',
        'title': 'BST Lab',
        'kind': 'class',
        'startsAt': day(6),
        'endsAt': null,
      },
      {
        'id': 'ev4',
        'courseId': 'c-des150',
        'departmentId': 'dept-arc',
        'title': 'Design Critique',
        'kind': 'institution',
        'startsAt': day(7),
        'endsAt': DateTime.now()
            .add(const Duration(days: 7, hours: 2))
            .toIso8601String(),
      },
      {
        'id': 'ev5',
        'courseId': null,
        'departmentId': null,
        'title': 'College Foundation Day',
        'kind': 'institution',
        'startsAt': day(14),
        'endsAt': DateTime.now()
            .add(const Duration(days: 14, hours: 2))
            .toIso8601String(),
      },
    ];
  }

  /* ============================================
     STUDENTS
     ============================================ */

  Future<List<Map<String, dynamic>>> getStudents() async {
    await _ensureLoaded();
    final rows = _students.map((s) => Map<String, dynamic>.from(s)).toList();
    rows.sort((a, b) =>
        (a['displayName'] ?? '').toString().compareTo((b['displayName'] ?? '').toString()));
    return rows;
  }

  Future<Map<String, dynamic>> getStudent(String studentId) async {
    await _ensureLoaded();
    final student = _students.firstWhere(
      (s) => s['id'] == studentId,
      orElse: () => <String, dynamic>{},
    );
    if (student.isEmpty) {
      throw Exception('Student not found');
    }
    return Map<String, dynamic>.from(student);
  }

  Future<Map<String, dynamic>> createStudent({
    required String displayName,
    required String email,
    required String phone,
    String? courseId,
    String? departmentId,
  }) async {
    await _ensureLoaded();
    final id = _id('u');
    final student = <String, dynamic>{
      'id': id,
      'displayName': displayName,
      'email': email,
      'phone': phone,
      'role': 'student',
      'courseIds': courseId == null ? <String>[] : [courseId],
      'rollNumber': 'STU-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      'isPhoneVerified': false,
      'createdAt': DateTime.now().toIso8601String(),
    };
    _students.add(student);
    if (departmentId != null && departmentId.isNotEmpty) {
      _enrollments.add({
        'id': _id('enr'),
        'studentId': id,
        'departmentId': departmentId,
        'enrolledAt': DateTime.now().toIso8601String(),
        'enrolledBy': 'u-admin-1',
      });
    }
    await _persistAll();
    return Map<String, dynamic>.from(student);
  }

  Future<Map<String, dynamic>> updateStudent({
    required String studentId,
    String? displayName,
    String? email,
    String? phone,
    String? courseId,
  }) async {
    await _ensureLoaded();
    final student = _students.firstWhere(
      (s) => s['id'] == studentId,
      orElse: () => <String, dynamic>{},
    );
    if (student.isEmpty) throw Exception('Student not found');
    if (displayName != null) student['displayName'] = displayName;
    if (email != null) student['email'] = email;
    if (phone != null) student['phone'] = phone;
    if (courseId != null) student['courseIds'] = [courseId];
    await _persistAll();
    return Map<String, dynamic>.from(student);
  }

  Future<void> deleteStudent(String studentId) async {
    await _ensureLoaded();
    _students.removeWhere((s) => s['id'] == studentId);
    _enrollments.removeWhere((e) => e['studentId'] == studentId);
    _attendance.removeWhere((a) => a['studentId'] == studentId);
    await _persistAll();
  }

  /* ============================================
     DEPARTMENTS
     ============================================ */

  Future<List<Map<String, dynamic>>> getDepartments() async {
    await _ensureLoaded();
    final rows = _departments.map((d) => Map<String, dynamic>.from(d)).toList();
    rows.sort((a, b) => (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));
    return rows;
  }

  Future<List<Map<String, dynamic>>> getStudentsByDepartment(
      String departmentId) async {
    await _ensureLoaded();
    final ids = _enrollments
        .where((e) => e['departmentId'] == departmentId)
        .map((e) => e['studentId'])
        .toSet();
    return _students
        .where((s) => ids.contains(s['id']))
        .map((s) => Map<String, dynamic>.from(s))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getStudentDepartments(
      String studentId) async {
    await _ensureLoaded();
    final ids = _enrollments
        .where((e) => e['studentId'] == studentId)
        .map((e) => e['departmentId'])
        .toSet();
    return _departments
        .where((d) => ids.contains(d['id']))
        .map((d) => Map<String, dynamic>.from(d))
        .toList();
  }

  Future<Map<String, dynamic>> enrollStudentInDepartment({
    required String studentId,
    required String departmentId,
  }) async {
    await _ensureLoaded();
    // This screen models enrollment as a move: remove previous departments.
    _enrollments.removeWhere((e) => e['studentId'] == studentId);
    final enrollment = <String, dynamic>{
      'id': _id('enr'),
      'studentId': studentId,
      'departmentId': departmentId,
      'enrolledAt': DateTime.now().toIso8601String(),
      'enrolledBy': 'u-admin-1',
    };
    _enrollments.add(enrollment);
    await _persistAll();
    return enrollment;
  }

  Future<void> unenrollStudentFromDepartment({
    required String studentId,
    required String departmentId,
  }) async {
    await _ensureLoaded();
    _enrollments.removeWhere(
      (e) => e['studentId'] == studentId && e['departmentId'] == departmentId,
    );
    await _persistAll();
  }

  Future<List<Map<String, dynamic>>> getStudentsByCourse(
      String courseId) async {
    await _ensureLoaded();
    return _students.where((s) {
      final ids = List<dynamic>.from(s['courseIds'] as List? ?? const []);
      return ids.contains(courseId);
    }).map((s) => Map<String, dynamic>.from(s)).toList();
  }

  /* ============================================
     ATTENDANCE
     ============================================ */

  Future<List<Map<String, dynamic>>> getAttendanceRecords({
    String? courseId,
    String? date,
  }) async {
    await _ensureLoaded();
    var rows = _attendance.where((r) {
      if (courseId != null && r['courseId'] != courseId) return false;
      if (date != null && r['date'] != date) return false;
      return true;
    }).map((r) => Map<String, dynamic>.from(r)).toList();
    rows.sort((a, b) => (b['date'] ?? '').toString().compareTo((a['date'] ?? '').toString()));
    return rows;
  }

  Future<Map<String, dynamic>> markAttendance({
    required String courseId,
    required String studentId,
    required String date,
    required String status,
    String? notes,
    String markedBy = 'u-teacher-1',
  }) async {
    await _ensureLoaded();
    final existing = _attendance.where(
      (r) =>
          r['courseId'] == courseId &&
          r['studentId'] == studentId &&
          r['date'] == date,
    ).toList();
    if (existing.isNotEmpty) {
      final row = existing.first;
      row['status'] = status;
      row['notes'] = notes ?? '';
      row['markedBy'] = markedBy;
      await _persistAll();
      return Map<String, dynamic>.from(row);
    }
    final row = <String, dynamic>{
      'id': _id('att'),
      'courseId': courseId,
      'studentId': studentId,
      'date': date,
      'status': status,
      'markedBy': markedBy,
      'notes': notes ?? '',
      'createdAt': DateTime.now().toIso8601String(),
    };
    _attendance.add(row);
    await _persistAll();
    return Map<String, dynamic>.from(row);
  }

  Future<List<Map<String, dynamic>>> bulkMarkAttendance({
    required String courseId,
    required String date,
    required List<Map<String, dynamic>> records,
  }) async {
    final results = <Map<String, dynamic>>[];
    for (final record in records) {
      results.add(await markAttendance(
        courseId: courseId,
        studentId: record['studentId']?.toString() ?? '',
        date: date,
        status: record['status']?.toString() ?? 'absent',
        notes: record['notes']?.toString() ?? '',
      ));
    }
    return results;
  }

  Future<List<Map<String, dynamic>>> getCourseStudentsWithAttendance({
    required String courseId,
    String? date,
  }) async {
    await _ensureLoaded();
    final students = await getStudentsByCourse(courseId);
    final effectiveDate = date ?? _today();
    final records = _attendance.where(
      (r) => r['courseId'] == courseId && r['date'] == effectiveDate,
    );
    return students.map((student) {
      final record = records.where((r) => r['studentId'] == student['id']).toList();
      return <String, dynamic>{
        ...student,
        'status': record.isNotEmpty ? record.first['status'] : 'absent',
        'notes': record.isNotEmpty ? (record.first['notes'] ?? '') : '',
        'date': effectiveDate,
      };
    }).toList();
  }

  /* ============================================
     TEACHER NOTES
     ============================================ */

  Future<List<Map<String, dynamic>>> getTeacherNotes({
    String? courseId,
    String? courseCode,
  }) async {
    await _ensureLoaded();
    var rows = _notes.where((n) {
      if (courseId != null && n['courseId'] != courseId) return false;
      if (courseCode != null &&
          !(n['courseCode'] ?? '')
              .toString()
              .toLowerCase()
              .contains(courseCode.toLowerCase())) {
        return false;
      }
      return true;
    }).map((n) => Map<String, dynamic>.from(n)).toList();
    rows.sort((a, b) =>
        (b['createdAt'] ?? '').toString().compareTo((a['createdAt'] ?? '').toString()));
    return rows;
  }

  Future<Map<String, dynamic>> createTeacherNote({
    required String courseId,
    required String bookName,
    required String courseCode,
    required String title,
    required String content,
  }) async {
    await _ensureLoaded();
    final now = DateTime.now().toIso8601String();
    final note = <String, dynamic>{
      'id': _id('note'),
      'courseId': courseId,
      'bookName': bookName,
      'courseCode': courseCode,
      'title': title,
      'content': content,
      'authorId': 'u-teacher-1',
      'createdAt': now,
      'updatedAt': now,
    };
    _notes.add(note);
    await _persistAll();
    return Map<String, dynamic>.from(note);
  }

  Future<Map<String, dynamic>> updateTeacherNote({
    required String id,
    String? bookName,
    String? courseCode,
    String? title,
    String? content,
  }) async {
    await _ensureLoaded();
    final note = _notes.firstWhere(
      (n) => n['id'] == id,
      orElse: () => <String, dynamic>{},
    );
    if (note.isEmpty) throw Exception('Note not found');
    if (bookName != null) note['bookName'] = bookName;
    if (courseCode != null) note['courseCode'] = courseCode;
    if (title != null) note['title'] = title;
    if (content != null) note['content'] = content;
    note['updatedAt'] = DateTime.now().toIso8601String();
    await _persistAll();
    return Map<String, dynamic>.from(note);
  }

  Future<void> deleteTeacherNote(String id) async {
    await _ensureLoaded();
    _notes.removeWhere((n) => n['id'] == id);
    await _persistAll();
  }

  /* ============================================
     CALENDAR
     ============================================ */

  Future<List<Map<String, dynamic>>> getCalendarEvents({
    String? departmentId,
    String? courseId,
  }) async {
    await _ensureLoaded();
    final rows = _calendar.where((e) {
      if (departmentId != null && e['departmentId'] != departmentId) {
        return false;
      }
      if (courseId != null && e['courseId'] != courseId) return false;
      return true;
    }).map((e) => Map<String, dynamic>.from(e)).toList();
    rows.sort((a, b) =>
        (a['startsAt'] ?? '').toString().compareTo((b['startsAt'] ?? '').toString()));
    return rows;
  }

  Future<Map<String, dynamic>> createCalendarEvent({
    required String title,
    required String kind,
    required DateTime startsAt,
    DateTime? endsAt,
    String? departmentId,
    String? courseId,
  }) async {
    await _ensureLoaded();
    final event = <String, dynamic>{
      'id': _id('ev'),
      'courseId': courseId,
      'departmentId': departmentId,
      'title': title,
      'kind': kind,
      'startsAt': startsAt.toIso8601String(),
      'endsAt': endsAt?.toIso8601String(),
    };
    _calendar.add(event);
    await _persist(_calendarKey, _calendar);
    return Map<String, dynamic>.from(event);
  }

  Future<Map<String, dynamic>> updateCalendarEvent({
    required String id,
    String? title,
    String? kind,
    DateTime? startsAt,
    DateTime? endsAt,
    String? departmentId,
    bool clearDepartment = false,
    bool clearEndsAt = false,
    String? courseId,
  }) async {
    await _ensureLoaded();
    final event = _calendar.firstWhere(
      (e) => e['id'] == id,
      orElse: () => <String, dynamic>{},
    );
    if (event.isEmpty) throw Exception('Calendar event not found');
    if (title != null) event['title'] = title;
    if (kind != null) event['kind'] = kind;
    if (startsAt != null) event['startsAt'] = startsAt.toIso8601String();
    if (endsAt != null) {
      event['endsAt'] = endsAt.toIso8601String();
    } else if (clearEndsAt) {
      event['endsAt'] = null;
    }
    if (departmentId != null) {
      event['departmentId'] = departmentId;
    } else if (clearDepartment) {
      event['departmentId'] = null;
    }
    if (courseId != null) event['courseId'] = courseId;
    await _persist(_calendarKey, _calendar);
    return Map<String, dynamic>.from(event);
  }

  Future<void> deleteCalendarEvent(String id) async {
    await _ensureLoaded();
    _calendar.removeWhere((e) => e['id'] == id);
    await _persist(_calendarKey, _calendar);
  }

  /* ============================================
     EXCEL IMPORT / EXPORT
     ============================================ */

  Future<Map<String, dynamic>> importStudents({
    required String courseId,
    required List<Map<String, dynamic>> rows,
  }) async {
    await _ensureLoaded();
    final imported = <Map<String, dynamic>>[];
    final errors = <Map<String, dynamic>>[];
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      final name = row['name']?.toString().trim() ?? '';
      final roll = row['rollNumber']?.toString().trim() ?? '';
      final contact = row['contact']?.toString().trim() ?? '';
      if (name.isEmpty || roll.isEmpty || contact.isEmpty) {
        errors.add({
          'row': i + 2,
          'message': 'Missing name, roll number, or contact',
        });
        continue;
      }
      final id = _id('u');
      final student = <String, dynamic>{
        'id': id,
        'displayName': name,
        'email': (row['email']?.toString().isNotEmpty ?? false)
            ? row['email'].toString()
            : '${roll.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}@example.edu',
        'phone': contact,
        'role': 'student',
        'courseIds': courseId.isEmpty ? <String>[] : [courseId],
        'rollNumber': roll,
        'isPhoneVerified': false,
        'createdAt': DateTime.now().toIso8601String(),
      };
      _students.add(student);
      final departmentId = row['departmentId']?.toString();
      if (departmentId != null && departmentId.isNotEmpty) {
        _enrollments.add({
          'id': _id('enr'),
          'studentId': id,
          'departmentId': departmentId,
          'enrolledAt': DateTime.now().toIso8601String(),
          'enrolledBy': 'u-admin-1',
        });
      }
      imported.add({
        'id': id,
        'name': name,
        'rollNumber': roll,
        'contact': contact,
      });
    }
    await _persistAll();
    return {'imported': imported.length, 'errors': errors, 'students': imported};
  }

  Future<Map<String, dynamic>> exportStudents({String? courseId}) async {
    await _ensureLoaded();
    final students = courseId == null || courseId.isEmpty
        ? _students
        : _students.where((s) {
            final ids = List<dynamic>.from(s['courseIds'] as List? ?? const []);
            return ids.contains(courseId);
          });
    final rows = students
        .map((s) => {
              'name': s['displayName'],
              'rollNumber': s['rollNumber'] ?? s['id'],
              'contact': s['phone'],
              'email': s['email'],
              'courseIds': jsonEncode(s['courseIds'] ?? const []),
            })
        .toList();
    return {
      'headers': ['name', 'rollNumber', 'contact', 'email', 'courseIds'],
      'rows': rows,
    };
  }

  Future<Map<String, dynamic>> exportAttendance({
    String? courseId,
    String? date,
  }) async {
    await _ensureLoaded();
    final records = await getAttendanceRecords(courseId: courseId, date: date);
    final rows = records
        .map((r) => {
              'id': r['id'],
              'courseId': r['courseId'],
              'studentId': r['studentId'],
              'date': r['date'],
              'status': r['status'],
              'markedBy': r['markedBy'],
              'notes': r['notes'],
            })
        .toList();
    return {
      'headers': [
        'id',
        'courseId',
        'studentId',
        'date',
        'status',
        'markedBy',
        'notes'
      ],
      'rows': rows,
    };
  }

  Future<Map<String, dynamic>> exportNotes({
    String? courseId,
    String? courseCode,
  }) async {
    await _ensureLoaded();
    final notes =
        await getTeacherNotes(courseId: courseId, courseCode: courseCode);
    final rows = notes
        .map((n) => {
              'id': n['id'],
              'courseId': n['courseId'],
              'bookName': n['bookName'],
              'courseCode': n['courseCode'],
              'title': n['title'],
              'content': n['content'],
              'authorId': n['authorId'],
              'createdAt': n['createdAt'],
              'updatedAt': n['updatedAt'],
            })
        .toList();
    return {
      'headers': [
        'id',
        'courseId',
        'bookName',
        'courseCode',
        'title',
        'content',
        'authorId',
        'createdAt',
        'updatedAt'
      ],
      'rows': rows,
    };
  }

  /* ============================================
     SUBMISSIONS
     ============================================ */

  Future<Map<String, dynamic>> createSubmission({
    required String assignmentId,
    required String studentId,
    required List<Map<String, dynamic>> attachments,
  }) async {
    await _ensureLoaded();
    final now = DateTime.now().toIso8601String();
    final submission = <String, dynamic>{
      'id': _id('sub'),
      'assignmentId': assignmentId,
      'studentId': studentId,
      'status': 'submitted',
      'submittedAt': now,
      'attachments': attachments,
      'grade': null,
      'effortScore': null,
    };
    _submissions.add(submission);
    await _persistAll();
    return Map<String, dynamic>.from(submission);
  }

  Future<List<Map<String, dynamic>>> getSubmissions() async {
    await _ensureLoaded();
    return _submissions.map((s) => Map<String, dynamic>.from(s)).toList();
  }

  /* ============================================
     CHAT
     ============================================ */

  Future<List<Map<String, dynamic>>> getMessages(String channelId) async {
    await _ensureLoaded();
    var rows = _messages
        .where((m) => m['channelId'] == channelId)
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
    if (rows.isEmpty) {
      rows = [
        {
          'id': _id('m'),
          'channelId': channelId,
          'authorId': 'u-teacher-1',
          'body': 'Welcome to the course!',
          'sentAt': DateTime.now()
              .subtract(const Duration(hours: 2))
              .toIso8601String(),
        },
      ];
    }
    rows.sort((a, b) =>
        (a['sentAt'] ?? '').toString().compareTo((b['sentAt'] ?? '').toString()));
    return rows;
  }

  Future<Map<String, dynamic>> postMessage({
    required String channelId,
    required String authorId,
    required String body,
  }) async {
    await _ensureLoaded();
    final message = <String, dynamic>{
      'id': _id('m'),
      'channelId': channelId,
      'authorId': authorId,
      'body': body,
      'sentAt': DateTime.now().toIso8601String(),
    };
    _messages.add(message);
    await _persistAll();
    return Map<String, dynamic>.from(message);
  }
}
