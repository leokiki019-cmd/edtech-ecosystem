import type { FastifyPluginAsync } from 'fastify';
import { randomUUID } from 'node:crypto';
import {
  getUsers,
  createUser,
  updateUser,
  getCourses,
  getStudentDepartments,
  enrollStudentInDepartment,
  unenrollStudentFromDepartment,
  getDepartmentsByStudent,
  getStudentsByCourse,
  addStudentToCourse,
  removeStudentFromCourse,
} from '../store/db.js';
import { authenticate } from '../middleware/auth.js';
import type { User, Role } from '@edtech/shared';

const studentsRoutes: FastifyPluginAsync = async (fastify) => {
  // GET /api/v1/students - list all students (admin/teacher)
  fastify.get(
    '/students',
    { preHandler: [authenticate] },
    async (request, reply) => {
      const users = getUsers();
      const students = users.filter((u) => u.role === 'student');
      return reply.send({ data: students });
    }
  );

  // GET /api/v1/students/:id - get a single student
  fastify.get(
    '/students/:id',
    { preHandler: [authenticate] },
    async (request, reply) => {
      const user = getUsers().find((u) => u.id === request.params.id);
      if (!user || user.role !== 'student') {
        return reply.code(404).send({ error: { code: 'NOT_FOUND', message: 'Student not found' } });
      }
      return reply.send({ data: user });
    }
  );

  // POST /api/v1/students - create a new student (admin only)
  fastify.post(
    '/students',
    { preHandler: [authenticate] },
    async (request, reply) => {
      const caller = request.user as { role?: Role } | undefined;
      if (caller?.role !== 'admin') {
        return reply.code(403).send({ error: { code: 'FORBIDDEN', message: 'Admin only' } });
      }
      const body = request.body as {
        displayName: string;
        email: string;
        phone: string;
        rollNumber?: string;
        courseId?: string;
        departmentId?: string;
      };
      const id = randomUUID();
      const now = new Date().toISOString();
      createUser({
        id,
        displayName: body.displayName,
        email: body.email,
        phone: body.phone,
        role: 'student',
        courseIds: body.courseId ? [body.courseId] : [],
        passwordHash: '',
        isPhoneVerified: 0,
        createdAt: now,
      });

      // If department specified, enroll student
      if (body.departmentId) {
        enrollStudentInDepartment({
          studentId: id,
          departmentId: body.departmentId,
          enrolledBy: caller?.id ?? id,
        });
      }

      const user = getUsers().find((u) => u.id === id);
      return reply.code(201).send({ data: user });
    }
  );

  // PUT /api/v1/students/:id - update a student (admin only)
  fastify.put(
    '/students/:id',
    { preHandler: [authenticate] },
    async (request, reply) => {
      const caller = request.user as { role?: Role } | undefined;
      if (caller?.role !== 'admin') {
        return reply.code(403).send({ error: { code: 'FORBIDDEN', message: 'Admin only' } });
      }
      const body = request.body as Partial<{
        displayName: string;
        email: string;
        phone: string;
        courseId: string;
      }>;
      const studentId = request.params.id as string;
      const updates: Record<string, any> = {};
      if (body.displayName !== undefined) updates.displayName = body.displayName;
      if (body.email !== undefined) updates.email = body.email;
      if (body.phone !== undefined) updates.phone = body.phone;
      updateUser(studentId, updates);

      // Update course if provided
      if (body.courseId !== undefined) {
        // Remove from all courses first, then add to new one
        const courses = getCourses();
        for (const course of courses) {
          if (course.studentIds.includes(studentId)) {
            removeStudentFromCourse(course.id, studentId);
          }
        }
        addStudentToCourse(body.courseId, studentId);
      }

      return reply.send({ data: getUsers().find((u) => u.id === studentId) });
    }
  );

  // DELETE /api/v1/students/:id - delete a student (admin only)
  fastify.delete(
    '/students/:id',
    { preHandler: [authenticate] },
    async (request, reply) => {
      const caller = request.user as { role?: Role } | undefined;
      if (caller?.role !== 'admin') {
        return reply.code(403).send({ error: { code: 'FORBIDDEN', message: 'Admin only' } });
      }
      const studentId = request.params.id as string;
      // Remove from all courses
      const courses = getCourses();
      for (const course of courses) {
        if (course.studentIds.includes(studentId)) {
          removeStudentFromCourse(course.id, studentId);
        }
      }
      // Remove department enrollments
      const deptEnrollments = getStudentDepartments(studentId);
      for (const d of deptEnrollments) {
        unenrollStudentFromDepartment(studentId, d.departmentId);
      }
      return reply.send({ data: { success: true } });
    }
  );

  // GET /api/v1/students/:id/departments - get departments for a student
  fastify.get(
    '/students/:id/departments',
    { preHandler: [authenticate] },
    async (request, reply) => {
      const departments = getDepartmentsByStudent(request.params.id as string);
      return reply.send({ data: departments });
    }
  );

  // POST /api/v1/students/:id/departments - enroll student in department
  fastify.post(
    '/students/:id/departments',
    { preHandler: [authenticate] },
    async (request, reply) => {
      const caller = request.user as { role?: Role } | undefined;
      if (caller?.role !== 'admin') {
        return reply.code(403).send({ error: { code: 'FORBIDDEN', message: 'Admin only' } });
      }
      const body = request.body as { departmentId: string };
      const enrollment = enrollStudentInDepartment({
        studentId: request.params.id as string,
        departmentId: body.departmentId,
        enrolledBy: caller?.id ?? request.params.id,
      });
      return reply.code(201).send({ data: enrollment });
    }
  );

  // DELETE /api/v1/students/:id/departments/:departmentId - unenroll
  fastify.delete(
    '/students/:id/departments/:departmentId',
    { preHandler: [authenticate] },
    async (request, reply) => {
      const caller = request.user as { role?: Role } | undefined;
      if (caller?.role !== 'admin') {
        return reply.code(403).send({ error: { code: 'FORBIDDEN', message: 'Admin only' } });
      }
      unenrollStudentFromDepartment(
        request.params.id as string,
        request.params.departmentId as string
      );
      return reply.send({ data: { success: true } });
    }
  );

  // GET /api/v1/courses/:courseId/students - get students in a course
  fastify.get(
    '/courses/:courseId/students',
    { preHandler: [authenticate] },
    async (request, reply) => {
      const students = getStudentsByCourse(request.params.courseId as string);
      return reply.send({ data: students });
    }
  );
};

export default studentsRoutes;
