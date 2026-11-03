import 'dart:convert';

import 'package:edtech_app/services/offline_store.dart';
import 'package:http/http.dart' as http;

/// An in-process replacement for the network client.
///
/// It answers the same REST routes as the Fastify API, but reads and writes the
/// persistent [OfflineStore] instead of making HTTP requests. This lets every
/// screen work in the standalone APK with no server at all.
class OfflineClient extends http.BaseClient {
  final OfflineStore _store = OfflineStore.instance;

  static final List<Map<String, dynamic>> _courses = [
    {
      'id': 'c-cs301',
      'code': 'CS 301',
      'title': 'Human-Computer Interaction',
      'teacherId': 'u-teacher-1',
      'studentIds': ['u-student-1', 'u-student-2', 'u-student-3'],
      'term': 'Fall 2026',
      'createdAt': '2026-08-20T00:00:00.000Z',
    },
    {
      'id': 'c-cs210',
      'code': 'CS 210',
      'title': 'Data Structures',
      'teacherId': 'u-teacher-2',
      'studentIds': ['u-student-1', 'u-student-4'],
      'term': 'Fall 2026',
      'createdAt': '2026-08-20T00:00:00.000Z',
    },
    {
      'id': 'c-des150',
      'code': 'DES 150',
      'title': 'Design Foundations',
      'teacherId': 'u-teacher-3',
      'studentIds': ['u-student-1', 'u-student-3', 'u-student-5'],
      'term': 'Fall 2026',
      'createdAt': '2026-08-20T00:00:00.000Z',
    },
  ];

  static List<Map<String, dynamic>> get _assignments => [
        {
          'id': 'a1',
          'courseId': 'c-cs301',
          'title': 'Heuristic Evaluation',
          'brief': 'Evaluate a web UI against Nielsen heuristics.',
          'dueAt': DateTime.now().add(const Duration(days: 3)).toIso8601String(),
          'status': 'open',
          'createdAt': '2026-09-01T00:00:00.000Z',
        },
        {
          'id': 'a2',
          'courseId': 'c-cs301',
          'title': 'Usability Study Report',
          'brief': 'Write up findings from a usability test.',
          'dueAt': DateTime.now().add(const Duration(days: 10)).toIso8601String(),
          'status': 'open',
          'createdAt': '2026-09-05T00:00:00.000Z',
        },
        {
          'id': 'a3',
          'courseId': 'c-cs210',
          'title': 'Binary Search Trees',
          'brief': 'Implement BST insert, delete, traverse.',
          'dueAt': DateTime.now().add(const Duration(days: 5)).toIso8601String(),
          'status': 'open',
          'createdAt': '2026-09-03T00:00:00.000Z',
        },
      ];

  Map<String, dynamic> _user({
    String role = 'admin',
    String displayName = 'Usman Shahid',
    String email = 'usman.shahid@example.edu',
    String phone = '+15550001005',
  }) {
    return {
      'id': role == 'admin' ? 'u-admin-1' : 'u-$role-1',
      'displayName': displayName,
      'email': email,
      'phone': phone,
      'role': role,
      'courseIds': ['c-cs301', 'c-cs210', 'c-des150'],
      'is_phone_verified': true,
      'createdAt': '2026-07-01T00:00:00.000Z',
    };
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final uri = request.url;
    final path = uri.path;
    final method = request.method;
    var body = <String, dynamic>{};
    if (request is http.Request && request.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(request.body);
        if (decoded is Map<String, dynamic>) body = decoded;
      } catch (_) {
        // Ignore malformed bodies in demo mode.
      }
    }

    try {
      final result = await _route(method, path, uri.queryParameters, body);
      return _json(result.status, result.body);
    } catch (error) {
      return _json(400, {
        'error': {'code': 'OFFLINE_ERROR', 'message': error.toString()},
      });
    }
  }

  Future<_Result> _route(
    String method,
    String path,
    Map<String, String> query,
    Map<String, dynamic> body,
  ) async {
    final segments = Uri.parse(path).pathSegments;
    if (path == '/health') {
      return _Result(200, {'status': 'ok', 'mode': 'offline'});
    }
    if (path == '/college') {
      final departments = await _store.getDepartments();
      return _Result(200, {
        'data': {
          'id': 'col-cttc',
          'name': 'Christian Technical Training Center',
          'shortName': 'CTTC',
          'createdAt': '2026-01-01T00:00:00.000Z',
          'departments': departments,
          'departmentCount': departments.length,
        },
      });
    }

    if (segments.length < 2 || segments[0] != 'api' || segments[1] != 'v1') {
      return _Result(404, {
        'error': {'code': 'NOT_FOUND', 'message': 'Unknown route $path'},
      });
    }
    final rest = segments.sublist(2);
    if (rest.isEmpty) {
      return _Result(404, {
        'error': {'code': 'NOT_FOUND', 'message': 'Unknown route $path'},
      });
    }

    switch (rest[0]) {
      case 'auth':
        return _auth(rest, method, body);
      case 'courses':
        return _coursesRoute(rest, method);
      case 'assignments':
        return _assignmentsRoute(rest, method, body);
      case 'students':
        return _studentsRoute(rest, method, body);
      case 'departments':
        return _departmentsRoute(rest, method);
      case 'attendance':
        return _attendanceRoute(rest, method, query, body);
      case 'notes':
        return _notesRoute(rest, method, query, body);
      case 'excel':
        return _excelRoute(rest, method, query, body);
      case 'calendar':
        return _calendarRoute(rest, method, query, body);
      case 'channels':
        return _channelsRoute(rest, method, body);
      case 'telemetry':
        return _Result(200, {'data': {'status': 'ok'}});
      case 'integrity':
        return _Result(404, {
          'error': {'code': 'NOT_FOUND', 'message': 'No integrity report'},
        });
      default:
        return _Result(404, {
          'error': {'code': 'NOT_FOUND', 'message': 'Unknown route $path'},
        });
    }
  }

  Future<_Result> _auth(
    List<String> rest,
    String method,
    Map<String, dynamic> body,
  ) async {
    if (method != 'POST' && !(method == 'GET' && rest.length > 1 && rest[1] == 'me')) {
      return _Result(405, {
        'error': {'code': 'METHOD_NOT_ALLOWED', 'message': 'Method not allowed'},
      });
    }
    if (rest.length > 1 && rest[1] == 'me') {
      return _Result(200, {'data': {'user': _user()}});
    }
    final role = body['role']?.toString() ?? 'admin';
    final name = body['display_name']?.toString() ??
        body['displayName']?.toString() ??
        (role == 'admin' ? 'Usman Shahid' : 'Demo $role');
    final email = body['email']?.toString() ?? 'demo@example.edu';
    final phone = body['phone']?.toString() ?? '+15550001005';
    final user = _user(
      role: role,
      displayName: name,
      email: email,
      phone: phone,
    );
    return _Result(200, {
      'data': {
        'token': 'offline-demo-token',
        'user': user,
      },
    });
  }

  Future<_Result> _coursesRoute(List<String> rest, String method) async {
    if (method != 'GET') {
      return _Result(405, {
        'error': {'code': 'METHOD_NOT_ALLOWED', 'message': 'Method not allowed'},
      });
    }
    if (rest.length == 1) {
      return _Result(200, {'data': _courses});
    }
    final courseId = rest[1];
    if (rest.length == 2) {
      final course = _courses.where((c) => c['id'] == courseId).toList();
      if (course.isEmpty) {
        return _Result(404, {
          'error': {'code': 'NOT_FOUND', 'message': 'Course not found'},
        });
      }
      return _Result(200, {'data': course.first});
    }
    if (rest.length == 3 && rest[2] == 'assignments') {
      final rows =
          _assignments.where((a) => a['courseId'] == courseId).toList();
      return _Result(200, {'data': rows});
    }
    if (rest.length == 3 && rest[2] == 'channels') {
      return _Result(200, {
        'data': [
          {
            'id': 'ch-general',
            'courseId': courseId,
            'name': 'General',
            'kind': 'discussion',
            'memberIds': ['u-teacher-1', 'u-student-1'],
          },
          {
            'id': 'ch-announce',
            'courseId': courseId,
            'name': 'Announcements',
            'kind': 'announcement',
            'memberIds': ['u-teacher-1', 'u-student-1'],
          },
        ],
      });
    }
    if (rest.length == 3 && rest[2] == 'students') {
      return _Result(200, {'data': await _store.getStudentsByCourse(courseId)});
    }
    return _Result(404, {
      'error': {'code': 'NOT_FOUND', 'message': 'Unknown course route'},
    });
  }

  Future<_Result> _assignmentsRoute(
    List<String> rest,
    String method,
    Map<String, dynamic> body,
  ) async {
    if (rest.length < 2) {
      return _Result(404, {
        'error': {'code': 'NOT_FOUND', 'message': 'Assignment not found'},
      });
    }
    final assignmentId = rest[1];
    if (rest.length == 2 && method == 'GET') {
      final assignment =
          _assignments.where((a) => a['id'] == assignmentId).toList();
      if (assignment.isEmpty) {
        return _Result(404, {
          'error': {'code': 'NOT_FOUND', 'message': 'Assignment not found'},
        });
      }
      return _Result(200, {'data': assignment.first});
    }
    if (rest.length == 3 && rest[2] == 'roster' && method == 'GET') {
      return _Result(200, {
        'data': {
          'roster': [
            {
              'studentId': 'u-student-1',
              'displayName': 'Aeliya',
              'status': 'submitted',
              'score': 84,
              'effortScore': 79,
            },
            {
              'studentId': 'u-student-2',
              'displayName': 'Sameer',
              'status': 'submitted',
              'score': 71,
              'effortScore': 68,
            },
            {
              'studentId': 'u-student-3',
              'displayName': 'Saifi',
              'status': 'pending',
              'score': 0,
              'effortScore': 0,
            },
          ],
        },
      });
    }
    if (rest.length == 3 && rest[2] == 'submissions' && method == 'POST') {
      final attachments = (body['attachments'] as List? ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .map((item) => <String, dynamic>{
                'id': item['id'] ?? 'att-${DateTime.now().microsecondsSinceEpoch}',
                'fileName': item['fileName'] ?? 'submission.txt',
                'mimeType': item['mimeType'] ?? 'text/plain',
                'sizeBytes': item['sizeBytes'] ?? 0,
                'url': item['url'] ?? 'offline://submission',
              })
          .toList();
      final submission = await _store.createSubmission(
        assignmentId: assignmentId,
        studentId: body['studentId']?.toString() ?? 'u-student-1',
        attachments: attachments,
      );
      return _Result(201, {'data': submission});
    }
    return _Result(404, {
      'error': {'code': 'NOT_FOUND', 'message': 'Unknown assignment route'},
    });
  }

  Future<_Result> _studentsRoute(
    List<String> rest,
    String method,
    Map<String, dynamic> body,
  ) async {
    if (rest.length == 1) {
      if (method == 'GET') {
        return _Result(200, {'data': await _store.getStudents()});
      }
      if (method == 'POST') {
        final student = await _store.createStudent(
          displayName: body['displayName']?.toString() ?? 'New Student',
          email: body['email']?.toString() ?? '',
          phone: body['phone']?.toString() ?? '',
          courseId: body['courseId']?.toString(),
          departmentId: body['departmentId']?.toString(),
        );
        return _Result(201, {'data': student});
      }
    }
    if (rest.length == 2) {
      final id = rest[1];
      if (method == 'GET') {
        return _Result(200, {'data': await _store.getStudent(id)});
      }
      if (method == 'PUT') {
        final student = await _store.updateStudent(
          studentId: id,
          displayName: body['displayName']?.toString(),
          email: body['email']?.toString(),
          phone: body['phone']?.toString(),
          courseId: body['courseId']?.toString(),
        );
        return _Result(200, {'data': student});
      }
      if (method == 'DELETE') {
        await _store.deleteStudent(id);
        return _Result(200, {'data': {'success': true}});
      }
    }
    if (rest.length == 3 && rest[2] == 'departments') {
      final id = rest[1];
      if (method == 'GET') {
        return _Result(200, {'data': await _store.getStudentDepartments(id)});
      }
      if (method == 'POST') {
        final enrollment = await _store.enrollStudentInDepartment(
          studentId: id,
          departmentId: body['departmentId']?.toString() ?? '',
        );
        return _Result(201, {'data': enrollment});
      }
    }
    if (rest.length == 4 && rest[2] == 'departments' && method == 'DELETE') {
      await _store.unenrollStudentFromDepartment(
        studentId: rest[1],
        departmentId: rest[3],
      );
      return _Result(200, {'data': {'success': true}});
    }
    return _Result(404, {
      'error': {'code': 'NOT_FOUND', 'message': 'Unknown student route'},
    });
  }

  Future<_Result> _departmentsRoute(List<String> rest, String method) async {
    if (method != 'GET') {
      return _Result(405, {
        'error': {'code': 'METHOD_NOT_ALLOWED', 'message': 'Method not allowed'},
      });
    }
    if (rest.length == 1) {
      return _Result(200, {'data': await _store.getDepartments()});
    }
    if (rest.length == 3 && rest[2] == 'students') {
      return _Result(200, {
        'data': await _store.getStudentsByDepartment(rest[1]),
      });
    }
    return _Result(404, {
      'error': {'code': 'NOT_FOUND', 'message': 'Unknown department route'},
    });
  }

  Future<_Result> _attendanceRoute(
    List<String> rest,
    String method,
    Map<String, String> query,
    Map<String, dynamic> body,
  ) async {
    if (rest.length == 1) {
      if (method == 'GET') {
        return _Result(200, {
          'data': await _store.getAttendanceRecords(
            courseId: query['courseId'],
            date: query['date'],
          ),
        });
      }
      if (method == 'POST') {
        final record = await _store.markAttendance(
          courseId: body['courseId']?.toString() ?? '',
          studentId: body['studentId']?.toString() ?? '',
          date: body['date']?.toString() ?? '',
          status: body['status']?.toString() ?? 'absent',
          notes: body['notes']?.toString(),
        );
        return _Result(201, {'data': record});
      }
    }
    if (rest.length == 2 && rest[1] == 'bulk' && method == 'POST') {
      final records = (body['records'] as List? ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      return _Result(201, {
        'data': await _store.bulkMarkAttendance(
          courseId: body['courseId']?.toString() ?? '',
          date: body['date']?.toString() ?? '',
          records: records,
        ),
      });
    }
    if (rest.length == 4 &&
        rest[1] == 'course' &&
        rest[3] == 'students' &&
        method == 'GET') {
      return _Result(200, {
        'data': await _store.getCourseStudentsWithAttendance(
          courseId: rest[2],
          date: query['date'],
        ),
      });
    }
    if (rest.length == 2 && method == 'GET') {
      final records = await _store.getAttendanceRecords();
      final record = records.where((r) => r['id'] == rest[1]).toList();
      if (record.isEmpty) {
        return _Result(404, {
          'error': {'code': 'NOT_FOUND', 'message': 'Record not found'},
        });
      }
      return _Result(200, {'data': record.first});
    }
    return _Result(404, {
      'error': {'code': 'NOT_FOUND', 'message': 'Unknown attendance route'},
    });
  }

  Future<_Result> _notesRoute(
    List<String> rest,
    String method,
    Map<String, String> query,
    Map<String, dynamic> body,
  ) async {
    if (rest.length == 1) {
      if (method == 'GET') {
        return _Result(200, {
          'data': await _store.getTeacherNotes(
            courseId: query['courseId'],
            courseCode: query['courseCode'],
          ),
        });
      }
      if (method == 'POST') {
        final note = await _store.createTeacherNote(
          courseId: body['courseId']?.toString() ?? '',
          bookName: body['bookName']?.toString() ?? '',
          courseCode: body['courseCode']?.toString() ?? '',
          title: body['title']?.toString() ?? 'Untitled',
          content: body['content']?.toString() ?? '',
        );
        return _Result(201, {'data': note});
      }
    }
    if (rest.length == 2) {
      final id = rest[1];
      if (method == 'PUT') {
        final note = await _store.updateTeacherNote(
          id: id,
          bookName: body['bookName']?.toString(),
          courseCode: body['courseCode']?.toString(),
          title: body['title']?.toString(),
          content: body['content']?.toString(),
        );
        return _Result(200, {'data': note});
      }
      if (method == 'DELETE') {
        await _store.deleteTeacherNote(id);
        return _Result(200, {'data': {'success': true}});
      }
      if (method == 'GET') {
        final notes = await _store.getTeacherNotes();
        final note = notes.where((n) => n['id'] == id).toList();
        if (note.isEmpty) {
          return _Result(404, {
            'error': {'code': 'NOT_FOUND', 'message': 'Note not found'},
          });
        }
        return _Result(200, {'data': note.first});
      }
    }
    return _Result(404, {
      'error': {'code': 'NOT_FOUND', 'message': 'Unknown notes route'},
    });
  }

  Future<_Result> _excelRoute(
    List<String> rest,
    String method,
    Map<String, String> query,
    Map<String, dynamic> body,
  ) async {
    if (rest.length == 3 &&
        rest[1] == 'import' &&
        rest[2] == 'students' &&
        method == 'POST') {
      final rows = (body['rows'] as List? ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      return _Result(201, {
        'data': await _store.importStudents(
          courseId: body['courseId']?.toString() ?? '',
          rows: rows,
        ),
      });
    }
    if (rest.length == 3 && rest[1] == 'export' && method == 'GET') {
      switch (rest[2]) {
        case 'students':
          return _Result(200, {
            'data': await _store.exportStudents(courseId: query['courseId']),
          });
        case 'attendance':
          return _Result(200, {
            'data': await _store.exportAttendance(
              courseId: query['courseId'],
              date: query['date'],
            ),
          });
        case 'notes':
          return _Result(200, {
            'data': await _store.exportNotes(
              courseId: query['courseId'],
              courseCode: query['courseCode'],
            ),
          });
      }
    }
    return _Result(404, {
      'error': {'code': 'NOT_FOUND', 'message': 'Unknown excel route'},
    });
  }

  Future<_Result> _calendarRoute(
    List<String> rest,
    String method,
    Map<String, String> query,
    Map<String, dynamic> body,
  ) async {
    if (rest.length == 1 && method == 'GET') {
      return _Result(200, {
        'data': await _store.getCalendarEvents(
          departmentId: query['departmentId'],
          courseId: query['courseId'],
        ),
      });
    }
    if (rest.length == 1 && method == 'POST') {
      final startsAt = DateTime.tryParse(body['startsAt']?.toString() ?? '');
      if (startsAt == null) {
        return _Result(400, {
          'error': {
            'code': 'INVALID_EVENT',
            'message': 'startsAt is required',
          },
        });
      }
      final event = await _store.createCalendarEvent(
        title: body['title']?.toString() ?? 'Untitled event',
        kind: body['kind']?.toString() ?? 'class',
        startsAt: startsAt,
        endsAt: DateTime.tryParse(body['endsAt']?.toString() ?? ''),
        departmentId: body['departmentId']?.toString(),
        courseId: body['courseId']?.toString(),
      );
      return _Result(201, {'data': event});
    }
    if (rest.length == 2) {
      final id = rest[1];
      if (method == 'PUT' || method == 'PATCH') {
        final event = await _store.updateCalendarEvent(
          id: id,
          title: body['title']?.toString(),
          kind: body['kind']?.toString(),
          startsAt: DateTime.tryParse(body['startsAt']?.toString() ?? ''),
          endsAt: DateTime.tryParse(body['endsAt']?.toString() ?? ''),
          clearEndsAt: body['endsAt'] == null,
          departmentId: body['departmentId']?.toString(),
          clearDepartment: body['departmentId'] == null,
        );
        return _Result(200, {'data': event});
      }
      if (method == 'DELETE') {
        await _store.deleteCalendarEvent(id);
        return _Result(200, {'data': {'success': true}});
      }
    }
    return _Result(404, {
      'error': {'code': 'NOT_FOUND', 'message': 'Unknown calendar route'},
    });
  }

  Future<_Result> _channelsRoute(
    List<String> rest,
    String method,
    Map<String, dynamic> body,
  ) async {
    if (rest.length == 3 && rest[2] == 'messages') {
      if (method == 'GET') {
        return _Result(200, {'data': await _store.getMessages(rest[1])});
      }
      if (method == 'POST') {
        final message = await _store.postMessage(
          channelId: rest[1],
          authorId: body['authorId']?.toString() ?? 'u-student-1',
          body: body['body']?.toString() ?? '',
        );
        return _Result(201, {'data': message});
      }
    }
    return _Result(404, {
      'error': {'code': 'NOT_FOUND', 'message': 'Unknown channel route'},
    });
  }

  http.StreamedResponse _json(int status, Object? payload) {
    final bytes = utf8.encode(jsonEncode(payload));
    return http.StreamedResponse(
      Stream.value(bytes),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
      contentLength: bytes.length,
    );
  }
}

class _Result {
  final int status;
  final Map<String, dynamic> body;
  _Result(this.status, this.body);
}
