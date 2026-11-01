import type { FastifyPluginAsync } from 'fastify';
import {
  getDepartments,
  getStudentsByDepartment,
  getDepartmentsByStudent,
  enrollStudentInDepartment,
  unenrollStudentFromDepartment,
} from '../store/db.js';
import { authenticate } from '../middleware/auth.js';

const departmentsRoutes: FastifyPluginAsync = async (fastify) => {
  // GET /api/v1/departments - list all departments
  fastify.get(
    '/departments',
    { preHandler: [authenticate] },
    async (request, reply) => {
      const departments = getDepartments();
      return reply.send({ data: departments });
    }
  );

  // GET /api/v1/departments/:id/students - students in a department
  fastify.get(
    '/departments/:id/students',
    { preHandler: [authenticate] },
    async (request, reply) => {
      const students = getStudentsByDepartment(request.params.id as string);
      return reply.send({ data: students });
    }
  );

  // POST /api/v1/departments - create department (admin only)
  fastify.post(
    '/departments',
    { preHandler: [authenticate] },
    async (request, reply) => {
      const caller = request.user as { role?: string } | undefined;
      if (caller?.role !== 'admin') {
        return reply.code(403).send({ error: { code: 'FORBIDDEN', message: 'Admin only' } });
      }
      const body = request.body as {
        collegeId: string;
        name: string;
        code: string;
        category: string;
        durationMonths: number;
      };
      const { randomUUID } = await import('node:crypto');
      const { db } = await import('../db.js');
      const id = randomUUID();
      const now = new Date().toISOString();
      db.prepare(
        `INSERT INTO departments (id, college_id, name, code, category, duration_months, created_at)
         VALUES (?, ?, ?, ?, ?, ?, ?)`
      ).run(id, body.collegeId, body.name, body.code, body.category, body.durationMonths, now);
      return reply.code(201).send({ data: { id, ...body, createdAt: now } });
    }
  );

  // PUT /api/v1/departments/:id - edit department (admin only)
  fastify.put(
    '/departments/:id',
    { preHandler: [authenticate] },
    async (request, reply) => {
      const caller = request.user as { role?: string } | undefined;
      if (caller?.role !== 'admin') {
        return reply.code(403).send({ error: { code: 'FORBIDDEN', message: 'Admin only' } });
      }
      const body = request.body as Partial<{
        name: string;
        code: string;
        category: string;
        durationMonths: number;
      }>;
      const { db } = await import('../db.js');
      const sets: string[] = [];
      const params: any[] = [];
      if (body.name !== undefined) { sets.push('name = ?'); params.push(body.name); }
      if (body.code !== undefined) { sets.push('code = ?'); params.push(body.code); }
      if (body.category !== undefined) { sets.push('category = ?'); params.push(body.category); }
      if (body.durationMonths !== undefined) { sets.push('duration_months = ?'); params.push(body.durationMonths); }
      params.push(request.params.id);
      db.prepare(`UPDATE departments SET ${sets.join(', ')} WHERE id = ?`).run(...params);
      return reply.send({ data: { success: true } });
    }
  );

  // DELETE /api/v1/departments/:id - delete department (admin only)
  fastify.delete(
    '/departments/:id',
    { preHandler: [authenticate] },
    async (request, reply) => {
      const caller = request.user as { role?: string } | undefined;
      if (caller?.role !== 'admin') {
        return reply.code(403).send({ error: { code: 'FORBIDDEN', message: 'Admin only' } });
      }
      const { db } = await import('../db.js');
      db.prepare('DELETE FROM departments WHERE id = ?').run(request.params.id);
      return reply.send({ data: { success: true } });
    }
  );

  // GET /api/v1/students/:studentId/departments - departments for a student
  fastify.get(
    '/students/:studentId/departments',
    { preHandler: [authenticate] },
    async (request, reply) => {
      const departments = getDepartmentsByStudent(request.params.studentId as string);
      return reply.send({ data: departments });
    }
  );

  // POST /api/v1/students/:studentId/departments - enroll
  fastify.post(
    '/students/:studentId/departments',
    { preHandler: [authenticate] },
    async (request, reply) => {
      const caller = request.user as { role?: string } | undefined;
      if (caller?.role !== 'admin') {
        return reply.code(403).send({ error: { code: 'FORBIDDEN', message: 'Admin only' } });
      }
      const body = request.body as { departmentId: string };
      const enrollment = enrollStudentInDepartment({
        studentId: request.params.studentId as string,
        departmentId: body.departmentId,
        enrolledBy: caller?.id ?? request.params.studentId,
      });
      return reply.code(201).send({ data: enrollment });
    }
  );

  // DELETE /api/v1/students/:studentId/departments/:departmentId - unenroll
  fastify.delete(
    '/students/:studentId/departments/:departmentId',
    { preHandler: [authenticate] },
    async (request, reply) => {
      const caller = request.user as { role?: string } | undefined;
      if (caller?.role !== 'admin') {
        return reply.code(403).send({ error: { code: 'FORBIDDEN', message: 'Admin only' } });
      }
      unenrollStudentFromDepartment(
        request.params.studentId as string,
        request.params.departmentId as string,
      );
      return reply.send({ data: { success: true } });
    }
  );
};

export default departmentsRoutes;
