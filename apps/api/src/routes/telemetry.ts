import crypto from "node:crypto";
import type { FastifyInstance, FastifyReply } from "fastify";
import type {
  ApiError,
  IntegrityReport,
  SignedTelemetryBatch,
  TelemetryEvent,
} from "../store/db";
import {
  createTelemetryBatch,
  getAssignment,
  getEffortScore,
  getIntegrityFlags,
  getSubmission,
  getSubmissionsByAssignment,
  getTelemetryBatches,
  getUser,
  setEffortScore,
  setIntegrityFlags,
  updateSubmission,
} from "../store/db";
import {
  buildEffortScore,
  computeEffortMetrics,
  computeIntegrityFlags,
} from "../services/effort";

const fail = (
  reply: FastifyReply,
  statusCode: number,
  code: string,
  message: string,
) => reply.code(statusCode).send({ error: { code, message } } satisfies ApiError);

/** Reconstruct the exact canonical JSON the extension signs over. Key order
 *  must match the client (batchId, studentId, assignmentId, createdAt, events). */
function canonicalBatch(batch: SignedTelemetryBatch): string {
  return JSON.stringify({
    batchId: batch.batchId,
    studentId: batch.studentId,
    assignmentId: batch.assignmentId,
    createdAt: batch.createdAt,
    events: batch.events,
  });
}

/** Verify an HMAC-SHA256 batch signature against the client's public JWK.
 *  The extension generates a single HMAC key per install and exports it as both
 *  "private" and "public" JWK (HMAC is symmetric). The clientPublicKey JWK
 *  carries the raw key material in its `k` field (base64url). */
function verifyBatchSignature(
  batch: SignedTelemetryBatch,
): { ok: boolean; reason?: string } {
  let publicKey: { kty?: string; k?: string };
  try {
    publicKey = JSON.parse(batch.clientPublicKey);
  } catch {
    return { ok: false, reason: "invalid-client-public-key" };
  }

  if (!publicKey.k || publicKey.kty !== "oct") {
    return { ok: false, reason: "invalid-hmac-jwk" };
  }

  let keyMaterial: Buffer;
  try {
    keyMaterial = Buffer.from(publicKey.k, "base64url");
  } catch {
    return { ok: false, reason: "invalid-key-material" };
  }

  const expected = crypto
    .createHmac("sha256", keyMaterial)
    .update(canonicalBatch(batch))
    .digest("base64url");

  const provided = Buffer.from(batch.clientSignature, "base64url");
  const wanted = Buffer.from(expected, "base64url");
  if (
    provided.length !== wanted.length ||
    !crypto.timingSafeEqual(provided, wanted)
  ) {
    return { ok: false, reason: "signature-mismatch" };
  }

  return { ok: true };
}

export async function telemetryRoutes(app: FastifyInstance) {
  app.post<{ Body: SignedTelemetryBatch }>(
    "/telemetry/batches",
    async (request, reply) => {
      const batch = request.body;

      if (
        !batch ||
        typeof batch.batchId !== "string" ||
        typeof batch.studentId !== "string" ||
        typeof batch.assignmentId !== "string" ||
        typeof batch.clientSignature !== "string" ||
        typeof batch.clientPublicKey !== "string" ||
        !Array.isArray(batch.events) ||
        batch.events.length === 0
      ) {
        return fail(
          reply,
          400,
          "INVALID_BATCH",
          "A signed batch with at least one telemetry event is required",
        );
      }

      // ---- Signature verification (new hardening step) ----
      const sigCheck = verifyBatchSignature(batch);
      if (!sigCheck.ok) {
        return fail(
          reply,
          401,
          "INVALID_SIGNATURE",
          `Telemetry batch signature invalid: ${sigCheck.reason}`,
        );
      }

      const assignment = await getAssignment(batch.assignmentId);
      if (!assignment) {
        return fail(reply, 404, "ASSIGNMENT_NOT_FOUND", "Assignment not found");
      }

      const student = await getUser(batch.studentId);
      if (!student || student.role !== "student") {
        return fail(reply, 404, "STUDENT_NOT_FOUND", "Student not found");
      }

      const inconsistent = batch.events.some(
        (event) =>
          event.assignmentId !== batch.assignmentId ||
          event.studentId !== batch.studentId,
      );
      if (inconsistent) {
        return fail(
          reply,
          400,
          "INCONSISTENT_EVENTS",
          "Every event must match the batch student and assignment",
        );
      }

      const metrics = computeEffortMetrics(batch.events);
      const sessionId = batch.events.at(-1)?.sessionId ?? batch.batchId;
      const score = buildEffortScore(
        sessionId,
        batch.studentId,
        batch.assignmentId,
        metrics,
      );
      const flags = computeIntegrityFlags(metrics);

      await createTelemetryBatch(batch);
      await setEffortScore(score);
      await setIntegrityFlags(batch.studentId, batch.assignmentId, flags);

      const existing = await getSubmissionsByAssignment(batch.assignmentId);
      const submission = existing.find(
        (entry) => entry.studentId === batch.studentId,
      );
      if (submission) {
        await updateSubmission(submission.id, { effortScore: score.score });
      }

      return reply.code(202).send({
        data: {
          batchId: batch.batchId,
          acceptedEvents: batch.events.length,
          effortScore: score,
        },
      });
    },
  );

  app.get<{ Params: { assignmentId: string; studentId: string } }>(
    "/integrity/:assignmentId/:studentId",
    async (request, reply) => {
      const { assignmentId, studentId } = request.params;
      const score = await getEffortScore(studentId, assignmentId);

      if (!score) {
        return fail(
          reply,
          404,
          "REPORT_NOT_FOUND",
          "No telemetry has been recorded for this student and assignment",
        );
      }

      const submissions = await getSubmissionsByAssignment(assignmentId);
      const submission = submissions.find(
        (entry) => entry.studentId === studentId,
      );

      const report: IntegrityReport = {
        submissionId: submission?.id ?? null,
        assignmentId,
        studentId,
        effortScore: score,
        flags: await getIntegrityFlags(studentId, assignmentId),
        replayAvailable: (await getTelemetryBatches()).some(
          (batch) =>
            batch.assignmentId === assignmentId && batch.studentId === studentId,
        ),
        generatedAt: new Date().toISOString(),
      };

      return { data: report };
    },
  );
}
