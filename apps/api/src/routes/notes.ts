import type { FastifyPluginAsync } from 'fastify';
import {
  getTeacherNotes,
  getTeacherNote,
  upsertTeacherNote,
  deleteTeacherNote,
} from '../store/db.js';
import { authenticate } from '../middleware/auth.js';

const notesRoutes: FastifyPluginAsync = async (fastify) => {
  // GET /api/v1/notes - list teacher notes
  // Query: courseId, courseCode
  fastify.get(
    '/notes',
    { preHandler: [authenticate] },
    async (request, reply) => {
      const { courseId, courseCode } = request.query as { courseId?: string; courseCode?: string };
      const notes = getTeacherNotes(courseId, courseCode);
      return reply.send({ data: notes });
    }
  );

  // GET /api/v1/notes/:id - single note
  fastify.get(
    '/notes/:id',
    { preHandler: [authenticate] },
    async (request, reply) => {
      const note = getTeacherNote(request.params.id as string);
      if (!note) {
        return reply.code(404).send({ error: { code: 'NOT_FOUND', message: 'Note not found' } });
      }
      return reply.send({ data: note });
    }
  );

  // POST /api/v1/notes - create a note (teacher/admin only)
  fastify.post(
    '/notes',
    { preHandler: [authenticate] },
    async (request, reply) => {
      const caller = request.user as { role?: string; id?: string } | undefined;
      const body = request.body as {
        courseId: string;
        bookName: string;
        courseCode: string;
        title: string;
        content: string;
      };
      const note = upsertTeacherNote({
        courseId: body.courseId,
        bookName: body.bookName,
        courseCode: body.courseCode,
        title: body.title,
        content: body.content,
        authorId: caller?.id ?? 'system',
      });
      return reply.code(201).send({ data: note });
    }
  );

  // PUT /api/v1/notes/:id - update a note (author or admin)
  fastify.put(
    '/notes/:id',
    { preHandler: [authenticate] },
    async (request, reply) => {
      const caller = request.user as { role?: string; id?: string } | undefined;
      const note = getTeacherNote(request.params.id as string);
      if (!note) {
        return reply.code(404).send({ error: { code: 'NOT_FOUND', message: 'Note not found' } });
      }
      if (caller?.role !== 'admin' && note.authorId !== caller?.id) {
        return reply.code(403).send({ error: { code: 'FORBIDDEN', message: 'Not the author' } });
      }
      const body = request.body as Partial<{
        bookName: string;
        courseCode: string;
        title: string;
        content: string;
      }>;
      const updated = upsertTeacherNote({
        id: note.id,
        courseId: note.courseId,
        bookName: body.bookName ?? note.bookName,
        courseCode: body.courseCode ?? note.courseCode,
        title: body.title ?? note.title,
        content: body.content ?? note.content,
        authorId: note.authorId,
      });
      return reply.send({ data: updated });
    }
  );

  // DELETE /api/v1/notes/:id - delete a note (author or admin)
  fastify.delete(
    '/notes/:id',
    { preHandler: [authenticate] },
    async (request, reply) => {
      const caller = request.user as { role?: string; id?: string } | undefined;
      const note = getTeacherNote(request.params.id as string);
      if (!note) {
        return reply.code(404).send({ error: { code: 'NOT_FOUND', message: 'Note not found' } });
      }
      if (caller?.role !== 'admin' && note.authorId !== caller?.id) {
        return reply.code(403).send({ error: { code: 'FORBIDDEN', message: 'Not the author' } });
      }
      deleteTeacherNote(note.id);
      return reply.send({ data: { success: true } });
    }
  );
};

export default notesRoutes;
