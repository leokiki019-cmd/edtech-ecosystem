import { randomUUID } from "node:crypto";
import type { FastifyInstance, FastifyReply } from "fastify";
import type { ApiError, Attachment, Submission, User } from "@edtech/shared";
import { assignments, courses, submissions, users } from "../store/memory";

const fail = (
  reply: FastifyReply,
  statusCode: number,
  code: string,
  message: string,
) => reply.code(statusCode).send({ error: { code, message } } satisfies ApiError);

export async function courseRoutes(app: FastifyInstance) {
  app.get("/courses", async () => ({
    data: courses.map((course) => ({
      ...course,
      teacherName:
        users.find((user) => user.id === course.teacherId)?.displayName ?? "Unassigned",
      studentCount: course.studentIds.length,
      openAssignmentCount: assignments.filter(
        (assignment) => assignment.courseId === course.id && assignment.status === "open",
      ).length,
    })),
  }));

  app.get<{ Params: { courseId: string } }>(
    "/courses/:courseId",
    async (request, reply) => {
      const course = courses.find((entry) => entry.id === request.params.courseId);
      if (!course) {
        return fail(reply, 404, "COURSE_NOT_FOUND", "Course not found");
      }

      const roster = course.studentIds
        .map((studentId) => users.find((user) => user.id === studentId))
        .filter((user): user is User => Boolean(user));

      return {
        data: {
          course,
          teacher: users.find((user) => user.id === course.teacherId) ?? null,
          roster,
          assignments: assignments.filter(
            (assignment) => assignment.courseId === course.id,
          ),
        },
      };
    },
  );

  app.get<{ Params: { courseId: string } }>(
    "/courses/:courseId/assignments",
    async (request, reply) => {
      const course = courses.find((entry) => entry.id === request.params.courseId);
      if (!course) {
        return fail(reply, 404, "COURSE_NOT_FOUND", "Course not found");
      }

      return {
        data: assignments
          .filter((assignment) => assignment.courseId === course.id)
          .sort((a, b) => a.dueAt.localeCompare(b.dueAt)),
      };
    },
  );

  app.get<{ Params: { assignmentId: string } }>(
    "/assignments/:assignmentId",
    async (request, reply) => {
      const assignment = assignments.find(
        (entry) => entry.id === request.params.assignmentId,
      );
      if (!assignment) {
        return fail(reply, 404, "ASSIGNMENT_NOT_FOUND", "Assignment not found");
      }

      const course = courses.find((entry) => entry.id === assignment.courseId) ?? null;
      return { data: { assignment, course } };
    },
  );

  app.get<{ Params: { assignmentId: string } }>(
    "/assignments/:assignmentId/roster",
    async (request, reply) => {
      const assignment = assignments.find(
        (entry) => entry.id === request.params.assignmentId,
      );
      if (!assignment) {
        return fail(reply, 404, "ASSIGNMENT_NOT_FOUND", "Assignment not found");
      }

      const course = courses.find((entry) => entry.id === assignment.courseId);
      if (!course) {
        return fail(reply, 404, "COURSE_NOT_FOUND", "Course not found");
      }

      const roster = course.studentIds.map((studentId) => {
        const student = users.find((user) => user.id === studentId);
        const submission = submissions.find(
          (entry) =>
            entry.assignmentId === assignment.id && entry.studentId === studentId,
        );

        return {
          studentId,
          displayName: student?.displayName ?? "Unknown student",
          status: submission?.status ?? "missing",
          submittedAt: submission?.submittedAt ?? null,
          effortScore: submission?.effortScore ?? null,
          grade: submission?.grade ?? null,
        };
      });

      return { data: { assignment, roster } };
    },
  );

  app.post<{
    Params: { assignmentId: string };
    Body: { studentId?: string; attachments?: Attachment[] };
  }>("/assignments/:assignmentId/submissions", async (request, reply) => {
    const assignment = assignments.find(
      (entry) => entry.id === request.params.assignmentId,
    );
    if (!assignment) {
      return fail(reply, 404, "ASSIGNMENT_NOT_FOUND", "Assignment not found");
    }

    const studentId = request.body?.studentId;
    if (!studentId) {
      return fail(reply, 400, "INVALID_BODY", "studentId is required");
    }

    const student = users.find((user) => user.id === studentId);
    if (!student) {
      return fail(reply, 404, "STUDENT_NOT_FOUND", "Student not found");
    }

    const course = courses.find((entry) => entry.id === assignment.courseId);
    if (!course?.studentIds.includes(studentId)) {
      return fail(reply, 403, "NOT_ENROLLED", "Student is not enrolled in this course");
    }

    const attachments = request.body?.attachments ?? [];
    if (!Array.isArray(attachments)) {
      return fail(reply, 400, "INVALID_BODY", "attachments must be an array");
    }

    if (assignment.status === "draft") {
      return fail(reply, 409, "ASSIGNMENT_DRAFT", "Assignment is not open for submissions");
    }

    const submittedAt = new Date().toISOString();
    const status: Submission["status"] =
      new Date(assignment.dueAt).getTime() < Date.now() ? "late" : "submitted";

    const existing = submissions.find(
      (entry) =>
        entry.assignmentId === assignment.id && entry.studentId === studentId,
    );

    if (existing) {
      existing.status = status;
      existing.submittedAt = submittedAt;
      existing.attachments = attachments;
      return reply.code(200).send({ data: existing });
    }

    const submission: Submission = {
      id: randomUUID(),
      assignmentId: assignment.id,
      studentId,
      status,
      submittedAt,
      attachments,
      grade: null,
      effortScore: null,
    };

    submissions.push(submission);
    return reply.code(201).send({ data: submission });
  });
}
