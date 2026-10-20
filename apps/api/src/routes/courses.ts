import type { FastifyInstance, FastifyReply } from "fastify";
import type { ApiError, Attachment, Submission, User } from "@edtech/shared";
import {
  createSubmission,
  getAssignment,
  getAssignmentsByCourse,
  getCourse,
  getCourses,
  getSubmission,
  getSubmissionsByAssignment,
  getUser,
  getUsers,
  updateSubmission,
} from "../store/db";

const fail = (
  reply: FastifyReply,
  statusCode: number,
  code: string,
  message: string,
) => reply.code(statusCode).send({ error: { code, message } } satisfies ApiError);

export async function courseRoutes(app: FastifyInstance) {
  app.get("/courses", async () => {
    const courses = await getCourses();
    const users = await getUsers();
    return {
      data: await Promise.all(
        courses.map(async (course) => {
          const teacher = users.find((u) => u.id === course.teacherId);
          const courseAssignments = await getAssignmentsByCourse(course.id);
          return {
            ...course,
            teacherName: teacher?.displayName ?? "Unassigned",
            studentCount: course.studentIds.length,
            openAssignmentCount: courseAssignments.filter(
              (a) => a.status === "open",
            ).length,
          };
        }),
      ),
    };
  });

  app.get<{ Params: { courseId: string } }>(
    "/courses/:courseId",
    async (request, reply) => {
      const course = await getCourse(request.params.courseId);
      if (!course) {
        return fail(reply, 404, "COURSE_NOT_FOUND", "Course not found");
      }

      const teacher = await getUser(course.teacherId);
      const rosterPromises = course.studentIds.map((id) => getUser(id));
      const roster = (await Promise.all(rosterPromises)).filter(
        (u): u is User => Boolean(u),
      );
      const courseAssignments = await getAssignmentsByCourse(course.id);

      return {
        data: {
          course,
          teacher: teacher ?? null,
          roster,
          assignments: courseAssignments,
        },
      };
    },
  );

  app.get<{ Params: { courseId: string } }>(
    "/courses/:courseId/assignments",
    async (request, reply) => {
      const course = await getCourse(request.params.courseId);
      if (!course) {
        return fail(reply, 404, "COURSE_NOT_FOUND", "Course not found");
      }

      return {
        data: (await getAssignmentsByCourse(course.id)).sort(
          (a, b) => a.dueAt.localeCompare(b.dueAt),
        ),
      };
    },
  );

  app.get<{ Params: { assignmentId: string } }>(
    "/assignments/:assignmentId",
    async (request, reply) => {
      const assignment = await getAssignment(request.params.assignmentId);
      if (!assignment) {
        return fail(reply, 404, "ASSIGNMENT_NOT_FOUND", "Assignment not found");
      }

      const course = await getCourse(assignment.courseId);
      return { data: { assignment, course: course ?? null } };
    },
  );

  app.get<{ Params: { assignmentId: string } }>(
    "/assignments/:assignmentId/roster",
    async (request, reply) => {
      const assignment = await getAssignment(request.params.assignmentId);
      if (!assignment) {
        return fail(reply, 404, "ASSIGNMENT_NOT_FOUND", "Assignment not found");
      }

      const course = await getCourse(assignment.courseId);
      if (!course) {
        return fail(reply, 404, "COURSE_NOT_FOUND", "Course not found");
      }

      const allSubmissions = await getSubmissionsByAssignment(assignment.id);
      const allUsers = await getUsers();
      const roster = course.studentIds.map((studentId) => {
        const student = allUsers.find((u) => u.id === studentId);
        const submission = allSubmissions.find(
          (entry) => entry.studentId === studentId,
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
    const assignment = await getAssignment(request.params.assignmentId);
    if (!assignment) {
      return fail(reply, 404, "ASSIGNMENT_NOT_FOUND", "Assignment not found");
    }

    const studentId = request.body?.studentId;
    if (!studentId) {
      return fail(reply, 400, "INVALID_BODY", "studentId is required");
    }

    const student = await getUser(studentId);
    if (!student) {
      return fail(reply, 404, "STUDENT_NOT_FOUND", "Student not found");
    }

    const course = await getCourse(assignment.courseId);
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

    const existingSubmissions = await getSubmissionsByAssignment(assignment.id);
    const existing = existingSubmissions.find(
      (entry) => entry.studentId === studentId,
    );

    if (existing) {
      await updateSubmission(existing.id, {
        status,
        submittedAt,
        attachments,
      });
      const updated = await getSubmission(existing.id);
      return reply.code(200).send({ data: updated });
    }

    const submission = await createSubmission({
      assignmentId: assignment.id,
      studentId,
      status,
      submittedAt,
      attachments,
    });
    return reply.code(201).send({ data: submission });
  });
}
