import { prisma } from '../db.js';
import { HttpError } from '../utils/httpError.js';
import { responseDict } from '../utils/serialize.js';
import { writeAudit, notifyUser } from './audit.js';

async function findSubmissionOr404(id) {
  const sub = await prisma.submissions.findUnique({ where: { id } });
  if (!sub) throw new HttpError(404, 'Resource not found.');
  return sub;
}

export async function addResponse({ submission_id, message }, actor, ip) {
  const sub = await findSubmissionOr404(submission_id);

  if (actor.role === 'secretary') {
    const a = await prisma.assignments.findFirst({
      where: { submission_id: sub.id, assigned_to: actor.id },
    });
    if (!a) throw new HttpError(403, 'You can only respond to submissions assigned to you.');
  }

  const resp = await prisma.$transaction(async (tx) => {
    const r = await tx.responses.create({
      data: { submission_id, responder_id: actor.id, message },
    });
    if (sub.status === 'pending') {
      await tx.submissions.update({ where: { id: sub.id }, data: { status: 'under_review' } });
      await tx.submission_status_history.create({
        data: { submission_id: sub.id, changed_by: actor.id, from_status: 'pending', to_status: 'under_review' },
      });
    }
    await writeAudit(tx, {
      userId: actor.id, action: 'ADD_RESPONSE', entityType: 'submission', entityId: sub.id,
      details: `Response added to submission ${sub.id}`, ip,
    });
    await notifyUser(tx, sub.user_id, sub.id,
      `A response has been added to your submission: '${sub.title}'`);
    return r;
  });

  const full = await prisma.responses.findUnique({
    where: { id: resp.id }, include: { responder: true },
  });
  return { status: 201, body: { message: 'Response added.', response: responseDict(full) } };
}

export async function getResponses(submissionId, actor) {
  const sub = await findSubmissionOr404(submissionId);

  if (actor.role === 'user' && sub.user_id !== actor.id) {
    throw new HttpError(403, 'Access denied.');
  }
  if (actor.role === 'secretary') {
    const a = await prisma.assignments.findFirst({
      where: { submission_id: submissionId, assigned_to: actor.id },
    });
    if (!a) throw new HttpError(403, 'Access denied.');
  }

  const responses = await prisma.responses.findMany({
    where: { submission_id: submissionId },
    include: { responder: true },
    orderBy: { created_at: 'asc' },
  });
  return { responses: responses.map(responseDict) };
}
