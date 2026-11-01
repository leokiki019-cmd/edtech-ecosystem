import type { FastifyPluginAsync, FastifyRequest } from 'fastify';
import {
  getAttendanceRecords,
  getAttendanceRecord,
  upsertAttendanceRecord,
  getStudentsByCourse,
} from '../store/db.js';
import { authenticate } from '../middleware/auth.js';

type AuthRequest = FastifyRequest & { user?: { id: string; role?: string } };

const attendanceRoutes: FastifyPluginAsync = async (fastify) => {
  // GET /api/v1/attendance - list attendance records
  // Query: courseId, date
  fastify.get(
    '/attendance',
    { preHandler: [authenticate] },
    async (request, reply) => {
      const { courseId, date } = request.query as { courseId?: string; date?: string };
      const records = getAttendanceRecords(courseId, date);
      return reply.send({ data: records });
    }
  );

  // GET /api/v1/attendance/:id - single record
  fastify.get(
    '/attendance/:id',
    { preHandler: [authenticate] },
    async (request, reply) => {
      const req = request as AuthRequest;
      const record = getAttendanceRecord((req.params as { id: string }).id);
      if (!record) {
        return reply.code(404).send({ error: { code: 'NOT_FOUND', message: 'Attendance record not found' } });
      }
      return reply.send({ data: record });
    }
  );

  // POST /api/v1/attendance - create or update attendance (teacher/admin)
  fastify.post(
    '/attendance',
    { preHandler: [authenticate] },
    async (request, reply) => {
      const req = request as AuthRequest;
      const caller = req.user;
      const body = request.body as {
        courseId: string;
        studentId: string;
        date: string; // YYYY-MM-DD
        status: 'present' | 'absent' | 'late' | 'excused';
        notes?: string;
      };
      const record = upsertAttendanceRecord({
        courseId: body.courseId,
        studentId: body.studentId,
        date: body.date,
        status: body.status,
        markedBy: caller?.id ?? 'system',
        notes: body.notes,
      });
      return reply.code(201).send({ data: record });
    }
  );

  // POST /api/v1/attendance/bulk - bulk mark attendance for a course/date
  fastify.post(
    '/attendance/bulk',
    { preHandler: [authenticate] },
    async (request, reply) => {
      const req = request as AuthRequest;
      const caller = req.user;
      const body = request.body as {
        courseId: string;
        date: string; // YYYY-MM-DD
        records: { studentId: string; status: 'present' | 'absent' | 'late' | 'excused'; notes?: string }[];
      };
      const results = body.records.map((r) =>
        upsertAttendanceRecord({
          courseId: body.courseId,
          studentId: r.studentId,
          date: body.date,
          status: r.status,
          markedBy: caller?.id ?? 'system',
          notes: r.notes,
        })
      );
      return reply.code(201).send({ data: results });
    }
  );

  // GET /api/v1/attendance/course/:courseId/students - students with attendance for a date
  fastify.get(
    '/attendance/course/:courseId/students',
    { preHandler: [authenticate] },
    async (request, reply) => {
      const req = request as AuthRequest;
      const { courseId } = req.params as { courseId: string };
      const { date } = request.query as { date?: string };
      const students = getStudentsByCourse(courseId);
      const records = getAttendanceRecords(courseId, date);
      const recordMap = new Map(records.map((r) => [r.studentId, r]));
      const result = students.map((s) => ({
        id: s.id,
        displayName: s.displayName,
        email: s.email,
        phone: s.phone,
        status: recordMap.get(s.id)?.status ?? 'absent',
        notes: recordMap.get(s.id)?.notes ?? '',
        date,
      }));
      return reply.send({ data: result });
    }
  );
};

export default attendanceRoutes;
