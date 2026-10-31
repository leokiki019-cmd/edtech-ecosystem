import 'dart:convert';

import 'package:edtech_app/config.dart';
import 'package:edtech_app/models/assignment.dart';
import 'package:edtech_app/models/attachment.dart';
import 'package:edtech_app/models/calendar_event.dart';
import 'package:edtech_app/models/college.dart';
import 'package:edtech_app/models/channel.dart';
import 'package:edtech_app/models/chat_message.dart';
import 'package:edtech_app/models/course.dart';
import 'package:edtech_app/models/effort_report.dart';
import 'package:edtech_app/models/submission.dart';
import 'package:http/http.dart' as http;

class ApiService {
  ApiService._internal();
  static final ApiService instance = ApiService._internal();
  factory ApiService() => instance;

  final http.Client _client = http.Client();

  /// Live college profile (name + departments) from the API.
  /// Falls back to the local CTTC demo copy when unreachable.
  Future<College> getCollege() async {
    try {
      final response = await _client
          .get(Uri.parse('${AppConfig.apiBaseUrl}/api/v1/college'))
          .timeout(const Duration(seconds: 8));
      _throwOnError(response);
      final data = jsonDecode(response.body)['data'];
      if (data == null) return College.demo;
      return College.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      return College.demo;
    }
  }

  Future<List<Course>> getCourses() async {
    try {
      final response = await _client.get(Uri.parse('${AppConfig.apiBaseUrl}/api/v1/courses'))
          .timeout(const Duration(seconds: 8));
      _throwOnError(response);
      final List<dynamic> data = jsonDecode(response.body)['data'] as List<dynamic>;
      return data.map((item) => Course.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return _demoCourses;
    }
  }

  Future<List<Assignment>> getAssignments(String courseId) async {
    try {
      final response = await _client.get(
        Uri.parse('${AppConfig.apiBaseUrl}/api/v1/courses/$courseId/assignments'),
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
      headers: <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(<String, dynamic>{
        'studentId': studentId,
        'attachments': attachments.map((item) => item.toJson()).toList(),
      }),
    );
    _throwOnError(response);
    return Submission.fromJson(jsonDecode(response.body)['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> postTelemetry(Map<String, dynamic> batch) async {
    final response = await _client.post(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/telemetry/batches'),
      headers: <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(batch),
    );
    _throwOnError(response);
    return jsonDecode(response.body)['data'] as Map<String, dynamic>;
  }

  /// Returns the latest integrity report, or null when the API has no
  /// telemetry recorded yet for this student and assignment (404).
  /// Throws on network errors or other API failures.
  Future<IntegrityReport?> getIntegrityReportOrNull(
    String assignmentId,
    String studentId,
  ) async {
    final response = await _client.get(
      Uri.parse(
        '${AppConfig.apiBaseUrl}/api/v1/integrity/$assignmentId/$studentId',
      ),
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
      final response = await _client.get(uri).timeout(const Duration(seconds: 8));
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
      headers: <String, String>{'Content-Type': 'application/json'},
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
      headers: <String, String>{'Content-Type': 'application/json'},
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
      headers: <String, String>{'Content-Type': 'application/json'},
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
      headers: <String, String>{'Content-Type': 'application/json'},
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
      headers: <String, String>{'Content-Type': 'application/json'},
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
      headers: <String, String>{
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
