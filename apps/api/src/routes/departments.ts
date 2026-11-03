import type { FastifyPluginAsync, FastifyRequest } from 'fastify';
import {
  createDepartment,
  deleteDepartment,
  enrollStudentInDepartment,
  getDepartments,
  getDepartmentsByStudent,
  getStudentsByDepartment,
  unenrollStudentFromDepartment,
  updateDepartment,
} from '../store/db.js';
import type { DepartmentCategory } from '../store/db.js';
import { authenticate } from '../middleware/auth.js';

type AuthRequest = FastifyRequest & { user?: { id: string; role?: string } };

const departmentsRoutes: FastifyPluginAsync = async (fastify) => {
  // GET /api/v1/departments - list all departments
  fastify.get(
    '/departments',
    { preHandler: [authenticate] },
    async (request, reply) => {
      const departments = getDepartments('col-cttc');
      return reply.send({ data: departments });
    }
  );

  // GET /api/v1/departments/:id/students - students in a department
  fastify.get(
    '/departments/:id/students',
    { preHandler: [authenticate] },
    async (request, reply) => {
      const req = request as AuthRequest;
      const students = getStudentsByDepartment((req.params as { id: string }).id);
      return reply.send({ data: students });
    }
  );

  // POST /api/v1/departments - create department (admin only)
  fastify.post(
    '/departments',
    { preHandler: [authenticate] },
    async (request, reply) => {
      const req = request as AuthRequest;
      const caller = req.user;
      if (caller?.role !== 'admin') {
        return reply.code(403).send({ error: { code: 'FORBIDDEN', message: 'Admin only' } });
      }
      const body = request.body as {
        collegeId?: string;
        name: string;
        code: string;
        category: DepartmentCategory;
        durationMonths: number;
      };
      const department = createDepartment({
        collegeId: body.collegeId ?? 'col-cttc',
        name: body.name,
        code: body.code,
        category: body.category,
        durationMonths: body.durationMonths,
      });
      return reply.code(201).send({ data: department });
    }
  );

  // PUT /api/v1/departments/:id - edit department (admin only)
  fastify.put(
    '/departments/:id',
    { preHandler: [authenticate] },
    async (request, reply) => {
      const req = request as AuthRequest;
      const caller = req.user;
      if (caller?.role !== 'admin') {
        return reply.code(403).send({ error: { code: 'FORBIDDEN', message: 'Admin only' } });
      }
      const body = request.body as Partial<{
        name: string;
        code: string;
        category: DepartmentCategory;
        durationMonths: number;
      }>;
      const department = updateDepartment(
        (req.params as { id: string }).id,
        body,
      );
      if (!department) {
        return reply.code(404).send({
          error: { code: 'NOT_FOUND', message: 'Department not found' },
        });
      }
      return reply.send({ data: department });
    }
  );

  // DELETE /api/v1/departments/:id - delete department (admin only)
  fastify.delete(
    '/departments/:id',
    { preHandler: [authenticate] },
    async (request, reply) => {
      const req = request as AuthRequest;
      const caller = req.user;
      if (caller?.role !== 'admin') {
        return reply.code(403).send({ error: { code: 'FORBIDDEN', message: 'Admin only' } });
      }
      const removed = deleteDepartment((req.params as { id: string }).id);
      if (!removed) {
        return reply.code(404).send({
          error: { code: 'NOT_FOUND', message: 'Department not found' },
        });
      }
      return reply.send({ data: { success: true } });
    }
  );

  // GET /api/v1/students/:studentId/departments - departments for a student
  fastify.get(
    '/students/:studentId/departments',
    { preHandler: [authenticate] },
    async (request, reply) => {
      const req = request as AuthRequest;
      const departments = getDepartmentsByStudent((req.params as { studentId: string }).studentId);
      return reply.send({ data: departments });
    }
  );

  // POST /api/v1/students/:studentId/departments - enroll
  fastify.post(
    '/students/:studentId/departments',
    { preHandler: [authenticate] },
    async (request, reply) => {
      const req = request as AuthRequest;
      const caller = req.user;
      if (caller?.role !== 'admin') {
        return reply.code(403).send({ error: { code: 'FORBIDDEN', message: 'Admin only' } });
      }
      const body = request.body as { departmentId: string };
      const enrollment = enrollStudentInDepartment({
        studentId: (req.params as { studentId: string }).studentId,
        departmentId: body.departmentId,
        enrolledBy: caller?.id ?? (req.params as { studentId: string }).studentId,
      });
      return reply.code(201).send({ data: enrollment });
    }
  );

  // DELETE /api/v1/students/:studentId/departments/:departmentId - unenroll
  fastify.delete(
    '/students/:studentId/departments/:departmentId',
    { preHandler: [authenticate] },
    async (request, reply) => {
      const req = request as AuthRequest;
      const caller = req.user;
      if (caller?.role !== 'admin') {
        return reply.code(403).send({ error: { code: 'FORBIDDEN', message: 'Admin only' } });
      }
      unenrollStudentFromDepartment(
        (req.params as { studentId: string }).studentId,
        (req.params as { departmentId: string }).departmentId,
      );
      return reply.send({ data: { success: true } });
    }
  );
};

export default departmentsRoutes;
