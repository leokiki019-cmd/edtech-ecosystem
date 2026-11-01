import 'dart:convert';

import 'package:edtech_app/config.dart';
import 'package:edtech_app/models/assignment.dart';
import 'package:edtech_app/models/attendance.dart';
import 'package:edtech_app/models/attachment.dart';
import 'package:edtech_app/models/calendar_event.dart';
import 'package:edtech_app/models/channel.dart';
import 'package:edtech_app/models/chat_message.dart';
import 'package:edtech_app/models/college.dart';
import 'package:edtech_app/models/course.dart';
import 'package:edtech_app/models/effort_report.dart';
import 'package:edtech_app/models/submission.dart';
import 'package:http/http.dart' as http;

class ApiService {
  ApiService._internal();
  static final ApiService instance = ApiService._internal();
  factory ApiService() => instance;

  /// Bearer token set by AuthProvider after login/signup/verify-sms/getMe.
  /// Included on every authenticated request.
  String? token;

  final http.Client _client = http.Client();

  Map<String, String> _authHeaders() {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /* ============================================
     COURSES
     ============================================ */
  Future<List<Course>> getCourses() async {
    try {
      final response = await _client.get(
        Uri.parse('${AppConfig.apiBaseUrl}/api/v1/courses'),
        headers: _authHeaders(),
      ).timeout(const Duration(seconds: 8));
      _throwOnError(response);
      final List<dynamic> data = jsonDecode(response.body)['data'] as List<dynamic>;
      return data.map((item) => Course.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return _demoCourses;
    }
  }

  /* ============================================
     COLLEGES
     ============================================ */
  Future<College?> getCollege() async {
    try {
      final response = await _client.get(
        Uri.parse('${AppConfig.apiBaseUrl}/college'),
        headers: _authHeaders(),
      ).timeout(const Duration(seconds: 8));
      if (response.statusCode == 404) {
        return null;
      }
      _throwOnError(response);
      return College.fromJson(jsonDecode(response.body)['data'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /* ============================================
     ASSIGNMENTS
     ============================================ */
  Future<List<Assignment>> getAssignments(String courseId) async {
    try {
      final response = await _client.get(
        Uri.parse('${AppConfig.apiBaseUrl}/api/v1/courses/$courseId/assignments'),
        headers: _authHeaders(),
      ).timeout(const Duration(seconds: 8));
      _throwOnError(response);
      final List<dynamic> data = jsonDecode(response.body)['data'] as List<dynamic>;
      return data.map((item) => Assignment.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return _demoAssignments;
    }
  }

  Future<Assignment> getAssignment(String assignmentId) async {
    try {
      final response = await _client.get(
        Uri.parse('${AppConfig.apiBaseUrl}/api/v1/assignments/$assignmentId'),
        headers: _authHeaders(),
      ).timeout(const Duration(seconds: 8));
      _throwOnError(response);
      return Assignment.fromJson(jsonDecode(response.body)['data'] as Map<String, dynamic>);
    } catch (_) {
      return _demoAssignments.first;
    }
  }

  Future<List<Map<String, dynamic>>> getRoster(String assignmentId) async {
    try {
      final response = await _client.get(
        Uri.parse('${AppConfig.apiBaseUrl}/api/v1/assignments/$assignmentId/roster'),
        headers: _authHeaders(),
      ).timeout(const Duration(seconds: 8));
      _throwOnError(response);
      return List<Map<String, dynamic>>.from(
        jsonDecode(response.body)['data']['roster'] as List<dynamic>,
      );
    } catch (_) {
      return [
        {'studentId': 'u-student-1', 'displayName': 'Alex Rivera', 'status': 'submitted', 'score': 84},
        {'studentId': 'u-student-2', 'displayName': 'Jordan Lee', 'status': 'submitted', 'score': 71},
        {'studentId': 'u-student-3', 'displayName': 'Sam Patel', 'status': 'pending', 'score': 0},
      ];
    }
  }

  Future<Submission> submitAssignment({
    required String assignmentId,
    required String studentId,
    List<Attachment> attachments = const [],
  }) async {
    final response = await _client.post(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/assignments/$assignmentId/submissions'),
      headers: _authHeaders(),
      body: jsonEncode(<String, dynamic>{
        'studentId': studentId,
        'attachments': attachments.map((item) => item.toJson()).toList(),
      }),
    );
    _throwOnError(response);
    return Submission.fromJson(jsonDecode(response.body)['data'] as Map<String, dynamic>);
  }

  /* ============================================
     STUDENTS
     ============================================ */

  Future<List<Map<String, dynamic>>> getStudents() async {
    final response = await _client.get(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/students'),
      headers: _authHeaders(),
    ).timeout(const Duration(seconds: 8));
    _throwOnError(response);
    return List<Map<String, dynamic>>.from(jsonDecode(response.body)['data'] as List<dynamic>);
  }

  Future<Map<String, dynamic>> getStudent(String studentId) async {
    final response = await _client.get(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/students/$studentId'),
      headers: _authHeaders(),
    ).timeout(const Duration(seconds: 8));
    _throwOnError(response);
    return jsonDecode(response.body)['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createStudent({
    required String displayName,
    required String email,
    required String phone,
    String? courseId,
    String? departmentId,
  }) async {
    final response = await _client.post(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/students'),
      headers: _authHeaders(),
      body: jsonEncode(<String, dynamic>{
        'displayName': displayName,
        'email': email,
        'phone': phone,
        if (courseId != null) 'courseId': courseId,
        if (departmentId != null) 'departmentId': departmentId,
      }),
    );
    _throwOnError(response);
    return jsonDecode(response.body)['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateStudent({
    required String studentId,
    String? displayName,
    String? email,
    String? phone,
    String? courseId,
  }) async {
    final response = await _client.put(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/students/$studentId'),
      headers: _authHeaders(),
      body: jsonEncode(<String, dynamic>{
        if (displayName != null) 'displayName': displayName,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (courseId != null) 'courseId': courseId,
      }),
    );
    _throwOnError(response);
    return jsonDecode(response.body)['data'] as Map<String, dynamic>;
  }

  Future<void> deleteStudent(String studentId) async {
    final response = await _client.delete(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/students/$studentId'),
      headers: _authHeaders(),
    );
    _throwOnError(response);
  }

  Future<List<Map<String, dynamic>>> getStudentDepartments(String studentId) async {
    final response = await _client.get(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/students/$studentId/departments'),
      headers: _authHeaders(),
    ).timeout(const Duration(seconds: 8));
    _throwOnError(response);
    return List<Map<String, dynamic>>.from(jsonDecode(response.body)['data'] as List<dynamic>);
  }

  Future<Map<String, dynamic>> enrollStudentInDepartment({
    required String studentId,
    required String departmentId,
  }) async {
    final response = await _client.post(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/students/$studentId/departments'),
      headers: _authHeaders(),
      body: jsonEncode(<String, String>{'departmentId': departmentId}),
    );
    _throwOnError(response);
    return jsonDecode(response.body)['data'] as Map<String, dynamic>;
  }

  Future<void> unenrollStudentFromDepartment({
    required String studentId,
    required String departmentId,
  }) async {
    final response = await _client.delete(
      Uri.parse(
        '${AppConfig.apiBaseUrl}/api/v1/students/$studentId/departments/$departmentId',
      ),
      headers: _authHeaders(),
    );
    _throwOnError(response);
  }

  Future<List<Map<String, dynamic>>> getStudentsByCourse(String courseId) async {
    final response = await _client.get(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/students/courses/$courseId/students'),
      headers: _authHeaders(),
    ).timeout(const Duration(seconds: 8));
    _throwOnError(response);
    return List<Map<String, dynamic>>.from(jsonDecode(response.body)['data'] as List<dynamic>);
  }

  /* ============================================
     ATTENDANCE
     ============================================ */

  Future<List<AttendanceRecord>> getAttendanceRecords({
    String? courseId,
    String? date,
  }) async {
    final query = <String, String>{};
    if (courseId != null) query['courseId'] = courseId;
    if (date != null) query['date'] = date;
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/v1/attendance').replace(queryParameters: query);
    final response = await _client.get(uri, headers: _authHeaders()).timeout(const Duration(seconds: 8));
    _throwOnError(response);
    final List<dynamic> data = jsonDecode(response.body)['data'] as List<dynamic>;
    return data.map((item) => AttendanceRecord.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<AttendanceRecord> markAttendance({
    required String courseId,
    required String studentId,
    required String date,
    required String status,
    String? notes,
  }) async {
    final response = await _client.post(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/attendance'),
      headers: _authHeaders(),
      body: jsonEncode(<String, dynamic>{
        'courseId': courseId,
        'studentId': studentId,
        'date': date,
        'status': status,
        if (notes != null) 'notes': notes,
      }),
    );
    _throwOnError(response);
    return AttendanceRecord.fromJson(jsonDecode(response.body)['data'] as Map<String, dynamic>);
  }

  Future<List<AttendanceRecord>> bulkMarkAttendance({
    required String courseId,
    required String date,
    required List<Map<String, dynamic>> records,
  }) async {
    final response = await _client.post(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/attendance/bulk'),
      headers: _authHeaders(),
      body: jsonEncode(<String, dynamic>{
        'courseId': courseId,
        'date': date,
        'records': records,
      }),
    );
    _throwOnError(response);
    final List<dynamic> data = jsonDecode(response.body)['data'] as List<dynamic>;
    return data.map((item) => AttendanceRecord.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<Map<String, dynamic>>> getCourseStudentsWithAttendance({
    required String courseId,
    String? date,
  }) async {
    final query = <String, String>{};
    if (date != null) query['date'] = date;
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/v1/attendance/course/$courseId/students').replace(queryParameters: query);
    final response = await _client.get(uri, headers: _authHeaders()).timeout(const Duration(seconds: 8));
    _throwOnError(response);
    return List<Map<String, dynamic>>.from(jsonDecode(response.body)['data'] as List<dynamic>);
  }

  /* ============================================
     TEACHER NOTES
     ============================================ */

  Future<List<TeacherNote>> getTeacherNotes({
    String? courseId,
    String? courseCode,
  }) async {
    final query = <String, String>{};
    if (courseId != null) query['courseId'] = courseId;
    if (courseCode != null) query['courseCode'] = courseCode;
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/v1/notes').replace(queryParameters: query);
    final response = await _client.get(uri, headers: _authHeaders()).timeout(const Duration(seconds: 8));
    _throwOnError(response);
    final List<dynamic> data = jsonDecode(response.body)['data'] as List<dynamic>;
    return data.map((item) => TeacherNote.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<TeacherNote> createTeacherNote({
    required String courseId,
    required String bookName,
    required String courseCode,
    required String title,
    required String content,
  }) async {
    final response = await _client.post(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/notes'),
      headers: _authHeaders(),
      body: jsonEncode(<String, String>{
        'courseId': courseId,
        'bookName': bookName,
        'courseCode': courseCode,
        'title': title,
        'content': content,
      }),
    );
    _throwOnError(response);
    return TeacherNote.fromJson(jsonDecode(response.body)['data'] as Map<String, dynamic>);
  }

  Future<TeacherNote> updateTeacherNote({
    required String id,
    String? bookName,
    String? courseCode,
    String? title,
    String? content,
  }) async {
    final response = await _client.put(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/notes/$id'),
      headers: _authHeaders(),
      body: jsonEncode(<String, dynamic>{
        if (bookName != null) 'bookName': bookName,
        if (courseCode != null) 'courseCode': courseCode,
        if (title != null) 'title': title,
        if (content != null) 'content': content,
      }),
    );
    _throwOnError(response);
    return TeacherNote.fromJson(jsonDecode(response.body)['data'] as Map<String, dynamic>);
  }

  Future<void> deleteTeacherNote(String id) async {
    final response = await _client.delete(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/notes/$id'),
      headers: _authHeaders(),
    );
    _throwOnError(response);
  }

  /* ============================================
     DEPARTMENTS
     ============================================ */

  Future<List<Map<String, dynamic>>> getDepartments() async {
    final response = await _client.get(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/departments'),
      headers: _authHeaders(),
    ).timeout(const Duration(seconds: 8));
    _throwOnError(response);
    return List<Map<String, dynamic>>.from(jsonDecode(response.body)['data'] as List<dynamic>);
  }

  Future<List<Map<String, dynamic>>> getStudentsByDepartment(String departmentId) async {
    final response = await _client.get(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/departments/$departmentId/students'),
      headers: _authHeaders(),
    ).timeout(const Duration(seconds: 8));
    _throwOnError(response);
    return List<Map<String, dynamic>>.from(jsonDecode(response.body)['data'] as List<dynamic>);
  }

  /* ============================================
     EXCEL IMPORT/EXPORT
     ============================================ */

  Future<Map<String, dynamic>> importStudentsFromExcel({
    required String courseId,
    required List<Map<String, dynamic>> rows,
  }) async {
    final response = await _client.post(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/excel/import/students'),
      headers: _authHeaders(),
      body: jsonEncode(<String, dynamic>{
        'courseId': courseId,
        'rows': rows,
      }),
    );
    _throwOnError(response);
    return jsonDecode(response.body)['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> exportStudentsToExcel({String? courseId}) async {
    final query = <String, String>{};
    if (courseId != null) query['courseId'] = courseId;
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/v1/excel/export/students').replace(queryParameters: query);
    final response = await _client.get(uri, headers: _authHeaders()).timeout(const Duration(seconds: 8));
    _throwOnError(response);
    return jsonDecode(response.body)['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> exportAttendanceToExcel({String? courseId, String? date}) async {
    final query = <String, String>{};
    if (courseId != null) query['courseId'] = courseId;
    if (date != null) query['date'] = date;
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/v1/excel/export/attendance').replace(queryParameters: query);
    final response = await _client.get(uri, headers: _authHeaders()).timeout(const Duration(seconds: 8));
    _throwOnError(response);
    return jsonDecode(response.body)['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> exportNotesToExcel({String? courseId, String? courseCode}) async {
    final query = <String, String>{};
    if (courseId != null) query['courseId'] = courseId;
    if (courseCode != null) query['courseCode'] = courseCode;
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/v1/excel/export/notes').replace(queryParameters: query);
    final response = await _client.get(uri, headers: _authHeaders()).timeout(const Duration(seconds: 8));
    _throwOnError(response);
    return jsonDecode(response.body)['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> postTelemetry(Map<String, dynamic> batch) async {
    final response = await _client.post(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/telemetry/batches'),
      headers: _authHeaders(),
      body: jsonEncode(batch),
    );
    _throwOnError(response);
    return jsonDecode(response.body)['data'] as Map<String, dynamic>;
  }

  Future<IntegrityReport?> getIntegrityReportOrNull(
    String assignmentId,
    String studentId,
  ) async {
    final response = await _client.get(
      Uri.parse(
        '${AppConfig.apiBaseUrl}/api/v1/integrity/$assignmentId/$studentId',
      ),
      headers: _authHeaders(),
    ).timeout(const Duration(seconds: 8));
    if (response.statusCode == 404) {
      return null;
    }
    _throwOnError(response);
    return IntegrityReport.fromJson(
      jsonDecode(response.body)['data'] as Map<String, dynamic>,
    );
  }

  Future<List<CalendarEvent>> getCalendar(String? userId) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/v1/calendar')
          .replace(queryParameters: userId == null ? null : <String, String>{'userId': userId});
      final response = await _client.get(uri, headers: _authHeaders()).timeout(const Duration(seconds: 8));
      _throwOnError(response);
      final List<dynamic> data = jsonDecode(response.body)['data'] as List<dynamic>;
      return data.map((item) => CalendarEvent.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return _demoCalendar;
    }
  }

  Future<List<ChatMessage>> getMessages(String channelId) async {
    try {
      final response = await _client.get(
        Uri.parse('${AppConfig.apiBaseUrl}/api/v1/channels/$channelId/messages'),
        headers: _authHeaders(),
      ).timeout(const Duration(seconds: 8));
      _throwOnError(response);
      final List<dynamic> data = jsonDecode(response.body)['data'] as List<dynamic>;
      return data.map((item) => ChatMessage.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [
        ChatMessage(id: 'm1', channelId: channelId, authorId: 'u-teacher-1', body: 'Welcome to the course!', sentAt: DateTime.now().subtract(const Duration(hours: 2))),
        ChatMessage(id: 'm2', channelId: channelId, authorId: 'u-student-1', body: 'Thanks, excited to start.', sentAt: DateTime.now().subtract(const Duration(hours: 1))),
      ];
    }
  }

  Future<ChatMessage> postMessage({
    required String channelId,
    required String authorId,
    required String body,
  }) async {
    final response = await _client.post(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/channels/$channelId/messages'),
      headers: _authHeaders(),
      body: jsonEncode(<String, String>{
        'authorId': authorId,
        'body': body,
      }),
    );
    _throwOnError(response);
    return ChatMessage.fromJson(jsonDecode(response.body)['data'] as Map<String, dynamic>);
  }

  Future<List<Channel>> getChannels(String courseId) async {
    try {
      final response = await _client.get(
        Uri.parse('${AppConfig.apiBaseUrl}/api/v1/courses/$courseId/channels'),
        headers: _authHeaders(),
      ).timeout(const Duration(seconds: 8));
      _throwOnError(response);
      final List<dynamic> data = jsonDecode(response.body)['data'] as List<dynamic>;
      return data.map((item) => Channel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [
        Channel(id: 'ch-general', courseId: courseId, name: 'General', kind: 'general', memberIds: const ['u-teacher-1', 'u-student-1']),
        Channel(id: 'ch-announce', courseId: courseId, name: 'Announcements', kind: 'announcement', memberIds: const ['u-teacher-1', 'u-student-1']),
      ];
    }
  }

  Future<Map<String, dynamic>> register({
    required String phone,
    required String email,
    required String displayName,
    required String password,
    required String role,
  }) async {
    final response = await _client.post(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/auth/register'),
      headers: _authHeaders(),
      body: jsonEncode(<String, dynamic>{
        'phone': phone,
        'email': email,
        'display_name': displayName,
        'password': password,
        'role': role,
      }),
    );
    _throwOnError(response);
    return jsonDecode(response.body)['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/auth/login'),
      headers: _authHeaders(),
      body: jsonEncode(<String, dynamic>{
        'phone': phone,
        'password': password,
      }),
    );
    _throwOnError(response);
    return jsonDecode(response.body)['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> sendSmsCode({
    required String phone,
  }) async {
    final response = await _client.post(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/auth/send-sms'),
      headers: _authHeaders(),
      body: jsonEncode(<String, dynamic>{
        'phone': phone,
      }),
    );
    _throwOnError(response);
    return jsonDecode(response.body)['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verifySmsCode({
    required String phone,
    required String code,
  }) async {
    final response = await _client.post(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/auth/verify-sms'),
      headers: _authHeaders(),
      body: jsonEncode(<String, dynamic>{
        'phone': phone,
        'code': code,
      }),
    );
    _throwOnError(response);
    return jsonDecode(response.body)['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMe({
    required String token,
  }) async {
    final response = await _client.get(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/auth/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    _throwOnError(response);
    return jsonDecode(response.body)['data'] as Map<String, dynamic>;
  }

  void _throwOnError(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('API error ${response.statusCode}: ${response.body}');
    }
  }

  static final List<Course> _demoCourses = [
    Course(
      id: 'c-cs301',
      code: 'CS 301',
      title: 'Human-Computer Interaction',
      teacherId: 'u-teacher-1',
      studentIds: const ['u-student-1'],
      term: 'Fall 2026',
      createdAt: DateTime(2026, 8, 20),
    ),
    Course(
      id: 'c-cs210',
      code: 'CS 210',
      title: 'Data Structures',
      teacherId: 'u-teacher-2',
      studentIds: const ['u-student-1'],
      term: 'Fall 2026',
      createdAt: DateTime(2026, 8, 20),
    ),
    Course(
      id: 'c-des150',
      code: 'DES 150',
      title: 'Design Foundations',
      teacherId: 'u-teacher-3',
      studentIds: const ['u-student-1'],
      term: 'Fall 2026',
      createdAt: DateTime(2026, 8, 20),
    ),
  ];

  static final List<Assignment> _demoAssignments = [
    Assignment(
      id: 'a1',
      courseId: 'c-cs301',
      title: 'Heuristic Evaluation',
      brief: 'Evaluate a web UI against Nielsen’s heuristics.',
      dueAt: DateTime.now().add(const Duration(days: 3)),
      status: 'open',
      createdAt: DateTime(2026, 9, 1),
    ),
    Assignment(
      id: 'a2',
      courseId: 'c-cs301',
      title: 'Usability Study Report',
      brief: 'Write up findings from a usability test.',
      dueAt: DateTime.now().add(const Duration(days: 10)),
      status: 'open',
      createdAt: DateTime(2026, 9, 5),
    ),
    Assignment(
      id: 'a3',
      courseId: 'c-cs210',
      title: 'Binary Search Trees',
      brief: 'Implement BST insert, delete, traverse.',
      dueAt: DateTime.now().add(const Duration(days: 5)),
      status: 'open',
      createdAt: DateTime(2026, 9, 3),
    ),
  ];

  static final List<CalendarEvent> _demoCalendar = [
    CalendarEvent(
      id: 'ev1',
      courseId: 'c-cs301',
      title: 'HCI Quiz 1',
      kind: 'exam',
      startsAt: DateTime.now().add(const Duration(days: 2, hours: 3)),
      endsAt: DateTime.now().add(const Duration(days: 2, hours: 4)),
    ),
    CalendarEvent(
      id: 'ev2',
      courseId: 'c-cs301',
      title: 'Heuristic Evaluation due',
      kind: 'assignment',
      startsAt: DateTime.now().add(const Duration(days: 3)),
      endsAt: null,
    ),
    CalendarEvent(
      id: 'ev3',
      courseId: 'c-cs210',
      title: 'BST Lab',
      kind: 'assignment',
      startsAt: DateTime.now().add(const Duration(days: 5)),
      endsAt: null,
    ),
    CalendarEvent(
      id: 'ev4',
      courseId: 'c-des150',
      title: 'Design Critique',
      kind: 'event',
      startsAt: DateTime.now().add(const Duration(days: 7)),
      endsAt: DateTime.now().add(const Duration(days: 7, hours: 2)),
    ),
    CalendarEvent(
      id: 'ev5',
      courseId: 'c-cs301',
      title: 'Midterm',
      kind: 'exam',
      startsAt: DateTime.now().add(const Duration(days: 14)),
      endsAt: DateTime.now().add(const Duration(days: 14, hours: 2)),
    ),
  ];
}
