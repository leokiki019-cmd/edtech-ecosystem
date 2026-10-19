import { randomUUID } from "node:crypto";
import type { FastifyInstance, FastifyReply } from "fastify";
import type { ApiError, ChatMessage } from "@edtech/shared";
import {
  calendarEvents,
  channels,
  courses,
  messages,
  users,
} from "../store/memory";

const fail = (
  reply: FastifyReply,
  statusCode: number,
  code: string,
  message: string,
) => reply.code(statusCode).send({ error: { code, message } } satisfies ApiError);

export async function classroomRoutes(app: FastifyInstance) {
  app.get<{ Querystring: { userId?: string } }>("/calendar", async (request, reply) => {
    const userId = request.query.userId;
    let courseIds: Set<string>;

    if (userId) {
      const user = users.find((entry) => entry.id === userId);
      if (!user) {
        return fail(reply, 404, "USER_NOT_FOUND", "User not found");
      }

      if (user.role === "admin") {
        courseIds = new Set(courses.map((course) => course.id));
      } else if (user.role === "teacher") {
        courseIds = new Set(
          courses
            .filter((course) => course.teacherId === user.id)
            .map((course) => course.id),
        );
      } else {
        courseIds = new Set(user.courseIds);
      }
    } else {
      courseIds = new Set(courses.map((course) => course.id));
    }

    const data = calendarEvents
      .filter((event) => event.courseId === null || courseIds.has(event.courseId))
      .sort((a, b) => a.startsAt.localeCompare(b.startsAt));

    return { data };
  });

  app.get<{ Params: { courseId: string } }>(
    "/courses/:courseId/channels",
    async (request, reply) => {
      const course = courses.find((entry) => entry.id === request.params.courseId);
      if (!course) {
        return fail(reply, 404, "COURSE_NOT_FOUND", "Course not found");
      }

      return {
        data: channels.filter((channel) => channel.courseId === course.id),
      };
    },
  );

  app.get<{ Params: { channelId: string } }>(
    "/channels/:channelId/messages",
    async (request, reply) => {
      const channel = channels.find(
        (entry) => entry.id === request.params.channelId,
      );
      if (!channel) {
        return fail(reply, 404, "CHANNEL_NOT_FOUND", "Channel not found");
      }

      const data = messages
        .filter((message) => message.channelId === channel.id)
        .sort((a, b) => a.sentAt.localeCompare(b.sentAt));

      return { data };
    },
  );

  app.post<{
    Params: { channelId: string };
    Body: { authorId?: string; body?: string };
  }>("/channels/:channelId/messages", async (request, reply) => {
    const channel = channels.find(
      (entry) => entry.id === request.params.channelId,
    );
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
      const author = users.find((entry) => entry.id === authorId);
      if (author?.role === "student") {
        return fail(
          reply,
          403,
          "ANNOUNCEMENT_RESTRICTED",
          "Students cannot post in announcement channels",
        );
      }
    }

    const message: ChatMessage = {
      id: randomUUID(),
      channelId: channel.id,
      authorId,
      body,
      sentAt: new Date().toISOString(),
    };

    messages.push(message);
    return reply.code(201).send({ data: message });
  });
}
