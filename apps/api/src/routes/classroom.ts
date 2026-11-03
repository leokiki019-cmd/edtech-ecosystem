import type { FastifyInstance, FastifyReply } from "fastify";
import type { ApiError, ChatMessage } from "../store/db";
import {
  createCalendarEvent,
  createMessage,
  deleteCalendarEvent,
  getCalendarEvents,
  getChannel,
  getChannelsByCourse,
  getCourse,
  getCourses,
  getMessages,
  getUser,
  getUsers,
  updateCalendarEvent,
} from "../store/db";
import type { CalendarEventKind } from "../store/db";

const fail = (
  reply: FastifyReply,
  statusCode: number,
  code: string,
  message: string,
) => reply.code(statusCode).send({ error: { code, message } } satisfies ApiError);

export async function classroomRoutes(app: FastifyInstance) {
  app.get<{
    Querystring: { userId?: string; departmentId?: string };
  }>("/calendar", async (request, reply) => {
    const userId = request.query.userId;
    const departmentId = request.query.departmentId;
    let courseIds: Set<string>;

    if (userId) {
      const user = await getUser(userId);
      if (!user) {
        return fail(reply, 404, "USER_NOT_FOUND", "User not found");
      }

      if (user.role === "admin") {
        courseIds = new Set((await getCourses()).map((course) => course.id));
      } else if (user.role === "teacher") {
        courseIds = new Set(
          (await getCourses())
            .filter((course) => course.teacherId === user.id)
            .map((course) => course.id),
        );
      } else {
        courseIds = new Set(user.courseIds);
      }
    } else {
      courseIds = new Set((await getCourses()).map((course) => course.id));
    }

    return { data: getCalendarEvents(courseIds, departmentId) };
  });

  app.post<{
    Body: {
      title?: string;
      kind?: CalendarEventKind;
      startsAt?: string;
      endsAt?: string | null;
      departmentId?: string | null;
      courseId?: string | null;
    };
  }>("/calendar", async (request, reply) => {
    const caller = (request as any).user as
      | { id: string; role: string }
      | undefined;
    if (caller?.role !== "admin" && caller?.role !== "teacher") {
      return fail(reply, 403, "FORBIDDEN", "Admin or teacher only");
    }

    const { title, kind, startsAt, endsAt, departmentId, courseId } =
      request.body ?? {};
    if (!title || !kind || !startsAt) {
      return fail(
        reply,
        400,
        "INVALID_BODY",
        "title, kind and startsAt are required",
      );
    }

    const event = createCalendarEvent({
      title,
      kind,
      startsAt,
      endsAt: endsAt ?? null,
      departmentId: departmentId ?? null,
      courseId: courseId ?? null,
    });
    return reply.code(201).send({ data: event });
  });

  app.put<{
    Params: { eventId: string };
    Body: {
      title?: string;
      kind?: CalendarEventKind;
      startsAt?: string;
      endsAt?: string | null;
      departmentId?: string | null;
      courseId?: string | null;
    };
  }>("/calendar/:eventId", async (request, reply) => {
    const caller = (request as any).user as
      | { id: string; role: string }
      | undefined;
    if (caller?.role !== "admin" && caller?.role !== "teacher") {
      return fail(reply, 403, "FORBIDDEN", "Admin or teacher only");
    }

    const event = updateCalendarEvent(request.params.eventId, request.body ?? {});
    if (!event) {
      return fail(reply, 404, "EVENT_NOT_FOUND", "Calendar event not found");
    }
    return { data: event };
  });

  app.delete<{ Params: { eventId: string } }>(
    "/calendar/:eventId",
    async (request, reply) => {
      const caller = (request as any).user as
        | { id: string; role: string }
        | undefined;
      if (caller?.role !== "admin" && caller?.role !== "teacher") {
        return fail(reply, 403, "FORBIDDEN", "Admin or teacher only");
      }

      if (!deleteCalendarEvent(request.params.eventId)) {
        return fail(reply, 404, "EVENT_NOT_FOUND", "Calendar event not found");
      }
      return { data: { success: true } };
    },
  );

  app.get<{ Params: { courseId: string } }>(
    "/courses/:courseId/channels",
    async (request, reply) => {
      const course = await getCourse(request.params.courseId);
      if (!course) {
        return fail(reply, 404, "COURSE_NOT_FOUND", "Course not found");
      }

      return {
        data: await getChannelsByCourse(course.id),
      };
    },
  );

  app.get<{ Params: { channelId: string } }>(
    "/channels/:channelId/messages",
    async (request, reply) => {
      const channel = await getChannel(request.params.channelId);
      if (!channel) {
        return fail(reply, 404, "CHANNEL_NOT_FOUND", "Channel not found");
      }

      const data = await getMessages(channel.id);
      data.sort((a, b) => a.sentAt.localeCompare(b.sentAt));

      return { data };
    },
  );

  app.post<{
    Params: { channelId: string };
    Body: { authorId?: string; body?: string };
  }>("/channels/:channelId/messages", async (request, reply) => {
    const channel = await getChannel(request.params.channelId);
    if (!channel) {
      return fail(reply, 404, "CHANNEL_NOT_FOUND", "Channel not found");
    }

    const authorId = request.body?.authorId;
    const body = request.body?.body?.trim();

    if (!authorId || !body) {
      return fail(reply, 400, "INVALID_BODY", "authorId and body are required");
    }

    if (!channel.memberIds.includes(authorId)) {
      return fail(reply, 403, "NOT_A_MEMBER", "User is not a member of this channel");
    }

    if (channel.kind === "announcement") {
      const author = await getUser(authorId);
      if (author?.role === "student") {
        return fail(
          reply,
          403,
          "ANNOUNCEMENT_RESTRICTED",
          "Students cannot post in announcement channels",
        );
      }
    }

    const message = await createMessage({
      channelId: channel.id,
      authorId,
      body,
    });
    return reply.code(201).send({ data: message });
  });
}
