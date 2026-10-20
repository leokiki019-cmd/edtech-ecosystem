import 'dart:convert';

import 'package:edtech_app/config.dart';
import 'package:edtech_app/models/assignment.dart';
import 'package:edtech_app/models/attachment.dart';
import 'package:edtech_app/models/calendar_event.dart';
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

  Future<List<Course>> getCourses() async {
    final response = await _client.get(Uri.parse('${AppConfig.apiBaseUrl}/api/v1/courses'));
    _throwOnError(response);
    final List<dynamic> data = jsonDecode(response.body)['data'] as List<dynamic>;
    return data.map((item) => Course.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<Assignment>> getAssignments(String courseId) async {
    final response = await _client.get(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/courses/$courseId/assignments'),
    );
    _throwOnError(response);
    final List<dynamic> data = jsonDecode(response.body)['data'] as List<dynamic>;
    return data.map((item) => Assignment.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<Assignment> getAssignment(String assignmentId) async {
    final response = await _client.get(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/assignments/$assignmentId'),
    );
    _throwOnError(response);
    return Assignment.fromJson(jsonDecode(response.body)['data'] as Map<String, dynamic>);
  }

  Future<List<Map<String, dynamic>>> getRoster(String assignmentId) async {
    final response = await _client.get(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/assignments/$assignmentId/roster'),
    );
    _throwOnError(response);
    return List<Map<String, dynamic>>.from(
      jsonDecode(response.body)['data']['roster'] as List<dynamic>,
    );
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

  Future<IntegrityReport> getIntegrityReport(
    String assignmentId,
    String studentId,
  ) async {
    final response = await _client.get(
      Uri.parse(
        '${AppConfig.apiBaseUrl}/api/v1/integrity/$assignmentId/$studentId',
      ),
    );
    _throwOnError(response);
    return IntegrityReport.fromJson(
      jsonDecode(response.body)['data'] as Map<String, dynamic>,
    );
  }

  Future<List<CalendarEvent>> getCalendar(String? userId) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/v1/calendar')
        .replace(queryParameters: userId == null ? null : <String, String>{'userId': userId});
    final response = await _client.get(uri);
    _throwOnError(response);
    final List<dynamic> data = jsonDecode(response.body)['data'] as List<dynamic>;
    return data.map((item) => CalendarEvent.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<ChatMessage>> getMessages(String channelId) async {
    final response = await _client.get(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/channels/$channelId/messages'),
    );
    _throwOnError(response);
    final List<dynamic> data = jsonDecode(response.body)['data'] as List<dynamic>;
    return data.map((item) => ChatMessage.fromJson(item as Map<String, dynamic>)).toList();
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
    final response = await _client.get(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/courses/$courseId/channels'),
    );
    _throwOnError(response);
    final List<dynamic> data = jsonDecode(response.body)['data'] as List<dynamic>;
    return data.map((item) => Channel.fromJson(item as Map<String, dynamic>)).toList();
  }

  void _throwOnError(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('API error ${response.statusCode}: ${response.body}');
    }
  }
}
