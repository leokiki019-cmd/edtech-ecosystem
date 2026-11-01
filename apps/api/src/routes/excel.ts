import type { FastifyPluginAsync } from 'fastify';
import { getStudentsByCourse, createUser, getUsers } from '../store/db.js';
import { authenticate } from '../middleware/auth.js';
import type { Role } from '@edtech/shared';

const excelRoutes: FastifyPluginAsync = async (fastify) => {
  // POST /api/v1/excel/import/students - import students from Excel
  // Body: { courseId: string, rows: StudentImportRow[] }
  fastify.post(
    '/excel/import/students',
    { preHandler: [authenticate] },
    async (request, reply) => {
      const caller = request.user as { role?: Role } | undefined;
      if (caller?.role !== 'admin') {
        return reply.code(403).send({ error: { code: 'FORBIDDEN', message: 'Admin only' } });
      }
      const body = request.body as {
        courseId: string;
        rows: { name: string; rollNumber: string; contact: string; departmentId?: string }[];
      };
      const imported: any[] = [];
      const errors: { row: number; message: string }[] = [];

      for (let i = 0; i < body.rows.length; i++) {
        const row = body.rows[i];
        const rowNum = i + 2; // header is row 1
        try {
          if (!row.name || !row.rollNumber || !row.contact) {
            errors.push({ row: rowNum, message: 'Missing name, roll number, or contact' });
            continue;
          }
          const id = `stu-${Date.now()}-${i}`;
          const now = new Date().toISOString();
          createUser({
            id,
            displayName: row.name,
            email: `${row.rollNumber.toLowerCase().replace(/\s/g, '')}@example.edu`,
            phone: row.contact,
            role: 'student',
            courseIds: body.courseId ? [body.courseId] : [],
            passwordHash: '',
            isPhoneVerified: 0,
            createdAt: now,
          });
          if (body.courseId) {
            const { addStudentToCourse } = await import('../store/db.js');
            addStudentToCourse(body.courseId, id);
          }
          if (row.departmentId) {
            const { enrollStudentInDepartment } = await import('../store/db.js');
            enrollStudentInDepartment({
              studentId: id,
              departmentId: row.departmentId,
              enrolledBy: caller?.id ?? id,
            });
          }
          imported.push({ id, name: row.name, rollNumber: row.rollNumber, contact: row.contact });
        } catch (err: any) {
          errors.push({ row: rowNum, message: err?.message ?? 'Unknown error' });
        }
      }

      return reply.code(201).send({ data: { imported: imported.length, errors, students: imported } });
    }
  );

  // GET /api/v1/excel/export/students - export students to Excel-compatible JSON
  // Query: courseId
  fastify.get(
    '/excel/export/students',
    { preHandler: [authenticate] },
    async (request, reply) => {
      const caller = request.user as { role?: Role } | undefined;
      if (caller?.role !== 'admin' && caller?.role !== 'teacher') {
        return reply.code(403).send({ error: { code: 'FORBIDDEN', message: 'Admin or teacher only' } });
      }
      const { courseId } = request.query as { courseId?: string };
      let students = getUsers().filter((u) => u.role === 'student');
      if (courseId) {
        const { getStudentsByCourse } = await import('../store/db.js');
        students = getStudentsByCourse(courseId);
      }
      const rows = students.map((s) => ({
        name: s.displayName,
        rollNumber: s.id, // using id as roll number placeholder
        contact: s.phone,
        email: s.email,
        courseIds: JSON.stringify(s.courseIds),
      }));
      return reply.send({ data: { headers: ['name', 'rollNumber', 'contact', 'email', 'courseIds'], rows } });
    }
  );

  // GET /api/v1/excel/export/attendance - export attendance to Excel-compatible JSON
  // Query: courseId, date
  fastify.get(
    '/excel/export/attendance',
    { preHandler: [authenticate] },
    async (request, reply) => {
      const { getAttendanceRecords } = await import('../store/db.js');
      const { courseId, date } = request.query as { courseId?: string; date?: string };
      const records = getAttendanceRecords(courseId, date);
      const rows = records.map((r) => ({
        id: r.id,
        courseId: r.courseId,
        studentId: r.studentId,
        date: r.date,
        status: r.status,
        markedBy: r.markedBy,
        notes: r.notes,
      }));
      return reply.send({ data: { headers: ['id', 'courseId', 'studentId', 'date', 'status', 'markedBy', 'notes'], rows } });
    }
  );

  // GET /api/v1/excel/export/notes - export teacher notes to Excel-compatible JSON
  // Query: courseId, courseCode
  fastify.get(
    '/excel/export/notes',
    { preHandler: [authenticate] },
    async (request, reply) => {
      const { getTeacherNotes } = await import('../store/db.js');
      const { courseId, courseCode } = request.query as { courseId?: string; courseCode?: string };
      const notes = getTeacherNotes(courseId, courseCode);
      const rows = notes.map((n) => ({
        id: n.id,
        courseId: n.courseId,
        bookName: n.bookName,
        courseCode: n.courseCode,
        title: n.title,
        content: n.content,
        authorId: n.authorId,
        createdAt: n.createdAt,
        updatedAt: n.updatedAt,
      }));
      return reply.send({ data: { headers: ['id', 'courseId', 'bookName', 'courseCode', 'title', 'content', 'authorId', 'createdAt', 'updatedAt'], rows } });
    }
  );
};

export default excelRoutes;
