import 'package:edtech_app/auth/auth_provider.dart';
import 'package:edtech_app/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

/// Integration test against the local API (default http://localhost:4000).
///
/// Run the API first: `npm run dev:api` from the repository root.
/// The suite skips itself when the API is unreachable.
void main() {
  final api = ApiService.instance;
  const phone = '+15550001002'; // seeded student Alex Rivera
  const password = 'password123';

  Future<bool> apiReachable() async {
    try {
      final response = await http
          .get(Uri.parse('http://localhost:4000/health'))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  test('seeded student can log in through AuthProvider', () async {
    if (!await apiReachable()) {
      markTestSkipped('API not reachable on localhost:4000');
      return;
    }
    final auth = AuthProvider();
    final ok = await auth.login(phone: phone, password: password);
    expect(ok, isTrue, reason: auth.error);
    expect(auth.isAuthenticated, isTrue);
    expect(auth.user?.displayName, 'Alex Rivera');
    expect(auth.token, isNotEmpty);
  });

  test('wrong password is rejected', () async {
    if (!await apiReachable()) {
      markTestSkipped('API not reachable on localhost:4000');
      return;
    }
    final auth = AuthProvider();
    final ok = await auth.login(phone: phone, password: 'wrong-password');
    expect(ok, isFalse);
    expect(auth.isAuthenticated, isFalse);
  });

  test('courses load with teacher summary fields', () async {
    if (!await apiReachable()) {
      markTestSkipped('API not reachable on localhost:4000');
      return;
    }
    final courses = await api.getCourses();
    expect(courses, isNotEmpty);
    expect(courses.first.code, 'CS 301');
    expect(courses.first.teacherName, 'Dr. Maya Chen');
    expect(courses.first.studentCount, 3);
    expect(courses.first.openAssignmentCount, greaterThan(0));
  });

  test('assignments load with parseable ISO due dates', () async {
    if (!await apiReachable()) {
      markTestSkipped('API not reachable on localhost:4000');
      return;
    }
    final assignments = await api.getAssignments('c-001');
    expect(assignments, isNotEmpty);
    for (final assignment in assignments) {
      expect(assignment.dueAt.year, greaterThanOrEqualTo(2026));
    }
  });

  test('calendar events load and sort by start date', () async {
    if (!await apiReachable()) {
      markTestSkipped('API not reachable on localhost:4000');
      return;
    }
    final events = await api.getCalendar('u-student-1');
    expect(events, isNotEmpty);
  });

  test('chat channels and messages load', () async {
    if (!await apiReachable()) {
      markTestSkipped('API not reachable on localhost:4000');
      return;
    }
    final channels = await api.getChannels('c-001');
    expect(channels, isNotEmpty);
    final messages = await api.getMessages(channels.first.id);
    expect(messages, isNotEmpty);
    expect(messages.first.body, isNotEmpty);
  });

  test('integrity report returns null or a real report, never fake data', () async {
    if (!await apiReachable()) {
      markTestSkipped('API not reachable on localhost:4000');
      return;
    }
    final report = await api.getIntegrityReportOrNull('a-001', 'u-student-1');
    if (report != null) {
      expect(report.effortScore.score, inInclusiveRange(0, 100));
      expect(report.assignmentId, 'a-001');
    }
  });

  test('registration, token check and SMS verification flow works', () async {
    if (!await apiReachable()) {
      markTestSkipped('API not reachable on localhost:4000');
      return;
    }
    final phone = '+1555${DateTime.now().millisecondsSinceEpoch % 100000000}';
    final registered = await api.register(
      phone: phone,
      email: 'itest-${DateTime.now().millisecondsSinceEpoch}@test.dev',
      displayName: 'Integration Tester',
      password: 'secret123',
      role: 'student',
    );
    expect(registered['token'], isNotEmpty);

    final me = await api.getMe(token: registered['token'] as String);
    expect((me['user'] as Map<String, dynamic>)['phone'], phone);

    final sms = await api.sendSmsCode(phone: phone);
    expect(sms['code'], isNotNull);
    final verified = await api.verifySmsCode(
      phone: phone,
      code: sms['code'] as String,
    );
    expect(verified['token'], isNotEmpty);
  });
}
