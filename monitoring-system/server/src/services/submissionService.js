import { prisma } from '../db.js';
import { HttpError } from '../utils/httpError.js';
import { parseIsoDate } from '../utils/dates.js';
import { submissionDict, assignmentDict, statusHistoryDict } from '../utils/serialize.js';
import { writeAudit, notifyUser } from './audit.js';

const STATUS_TRANSITIONS = {
  pending: ['under_review', 'assigned'],
  under_review: ['assigned', 'resolved'],
  assigned: ['under_review', 'resolved'],
  resolved: ['closed'],
  closed: [],
};

const SUB_WITH = {
  submitter: true,
  responses: { include: { responder: true }, orderBy: { created_at: 'asc' } },
  status_history: { include: { actor: true }, orderBy: { changed_at: 'asc' } },
};

async function findSubmissionOr404(id, include) {
  const sub = await prisma.submissions.findUnique({ where: { id }, include });
  if (!sub) throw new HttpError(404, 'Resource not found.');
  return sub;
}

export async function createSubmission(userId, data, ip) {
  const submitter = await prisma.users.findUnique({ where: { id: userId } });
  const created = await prisma.$transaction(async (tx) => {
    const sub = await tx.submissions.create({
      data: {
        user_id: userId,
        title: data.title,
        description: data.description,
        category: data.category ?? 'other',
        priority: data.priority ?? 'medium',
      },
    });
    await tx.submission_status_history.create({
      data: { submission_id: sub.id, changed_by: userId, from_status: null, to_status: sub.status },
    });
    await writeAudit(tx, {
      userId, action: 'CREATE_SUBMISSION', entityType: 'submission', entityId: sub.id,
      details: `Title: ${sub.title}`, ip,
    });
    const admins = await tx.users.findMany({ where: { role: 'admin', is_active: true } });
    for (const admin of admins) {
      await notifyUser(tx, admin.id, sub.id,
        `New submission: '${sub.title}' from ${submitter ? submitter.name : 'user'}`);
    }
    return sub;
  });
  const full = await findSubmissionOr404(created.id, { submitter: true });
  return { status: 201, body: { message: 'Submission created.', submission: submissionDict(full) } };
}

export async function getSubmissions(user, {
  page = 1, perPage = 20, status, category, priority, search, from, to, assignedTo,
} = {}) {
  const where = {};
  if (user.role === 'user') {
    where.user_id = user.id;
  } else if (user.role === 'secretary') {
    const mine = await prisma.assignments.findMany({
      where: { assigned_to: user.id }, select: { submission_id: true },
    });
    where.id = { in: mine.map((a) => a.submission_id) };
  }
  if (status) where.status = status;
  if (category) where.category = category;
  if (priority) where.priority = priority;
  if (assignedTo) where.assignment = { assigned_to: assignedTo };
  if (search) {
    const term = search.trim();
    where.OR = [{ title: { contains: term } }, { description: { contains: term } }];
  }
  if (from != null) {
    const d = parseIsoDate(from);
    if (!d) throw new HttpError(400, "Invalid 'from' date. Use ISO-8601 format.");
    where.created_at = { ...(where.created_at || {}), gte: d };
  }
  if (to != null) {
    const d = parseIsoDate(to);
    if (!d) throw new HttpError(400, "Invalid 'to' date. Use ISO-8601 format.");
    where.created_at = { ...(where.created_at || {}), lte: d };
  }

  if (page < 1 || perPage < 1 || perPage > 100) {
    throw new HttpError(400, 'page must be >= 1 and per_page must be between 1 and 100.');
  }

  const [total, items] = await prisma.$transaction([
    prisma.submissions.count({ where }),
    prisma.submissions.findMany({
      where,
      include: { submitter: true },
      orderBy: [{ created_at: 'asc' }, { id: 'asc' }],
      skip: (page - 1) * perPage,
      take: perPage,
    }),
  ]);

  return {
    submissions: items.map((s) => submissionDict(s)),
    total,
    pages: total === 0 ? 0 : Math.ceil(total / perPage),
    page,
    per_page: perPage,
  };
}

async function assertCanView(sub, user) {
  if (user.role === 'user' && sub.user_id !== user.id) {
    throw new HttpError(403, 'Access denied.');
  }
  if (user.role === 'secretary') {
    const a = await prisma.assignments.findFirst({
      where: { submission_id: sub.id, assigned_to: user.id },
    });
    if (!a) throw new HttpError(403, 'Access denied.');
  }
}

export async function getSubmission(subId, user) {
  const sub = await findSubmissionOr404(subId, SUB_WITH);
  await assertCanView(sub, user);
  return { submission: submissionDict(sub, { includeResponses: true }) };
}

export async function getStatusHistory(subId, user) {
  const sub = await findSubmissionOr404(subId, {
    status_history: { include: { actor: true }, orderBy: { changed_at: 'asc' } },
  });
  await assertCanView(sub, user);
  return { status_history: sub.status_history.map(statusHistoryDict) };
}

export async function updateStatus(subId, newStatus, actor, ip) {
  const sub = await findSubmissionOr404(subId);
  const oldStatus = sub.status;
  if (actor.role === 'secretary') {
    const a = await prisma.assignments.findFirst({
      where: { submission_id: subId, assigned_to: actor.id },
    });
    if (!a) throw new HttpError(403, 'You can only update submissions assigned to you.');
  }
  if (newStatus === oldStatus) {
    throw new HttpError(409, 'Submission is already in that status.');
  }
  if (!(STATUS_TRANSITIONS[oldStatus] || []).includes(newStatus)) {
    throw new HttpError(409, `Invalid status transition from '${oldStatus}' to '${newStatus}'.`);
  }
  await prisma.$transaction(async (tx) => {
    await tx.submissions.update({ where: { id: subId }, data: { status: newStatus } });
    await tx.submission_status_history.create({
      data: { submission_id: subId, changed_by: actor.id, from_status: oldStatus, to_status: newStatus },
    });
    await writeAudit(tx, {
      userId: actor.id, action: 'UPDATE_STATUS', entityType: 'submission', entityId: subId,
      details: `${oldStatus} → ${newStatus}`, ip,
    });
    await notifyUser(tx, sub.user_id, subId,
      `Your submission '${sub.title}' status changed to '${newStatus}'.`);
  });
  const full = await findSubmissionOr404(subId, { submitter: true });
  return { message: 'Status updated.', submission: submissionDict(full) };
}

export async function deleteSubmission(subId, actor, ip) {
  const sub = await findSubmissionOr404(subId);
  await prisma.$transaction(async (tx) => {
    await writeAudit(tx, {
      userId: actor.id, action: 'DELETE_SUBMISSION', entityType: 'submission', entityId: subId,
      details: `Deleted: ${sub.title}`, ip,
    });
    await tx.responses.deleteMany({ where: { submission_id: subId } });
    await tx.submission_status_history.deleteMany({ where: { submission_id: subId } });
    await tx.notifications.deleteMany({ where: { submission_id: subId } });
    await tx.assignments.deleteMany({ where: { submission_id: subId } });
    await tx.submissions.delete({ where: { id: subId } });
  });
  return { message: 'Submission deleted.' };
}

export async function assignSubmission({ submission_id, assigned_to, notes = '' }, actor, ip) {
  const sub = await findSubmissionOr404(submission_id);
  const secretary = await prisma.users.findUnique({ where: { id: assigned_to } });
  if (!secretary) throw new HttpError(404, 'Resource not found.');
  if (secretary.role !== 'secretary' || !secretary.is_active) {
    throw new HttpError(400, 'Target user is not a secretary.');
  }
  const assignment = await prisma.$transaction(async (tx) => {
    await tx.assignments.deleteMany({ where: { submission_id } });
    const a = await tx.assignments.create({
      data: { submission_id, assigned_to, assigned_by: actor.id, notes },
    });
    await tx.submissions.update({ where: { id: submission_id }, data: { status: 'assigned' } });
    await tx.submission_status_history.create({
      data: { submission_id, changed_by: actor.id, from_status: sub.status, to_status: 'assigned' },
    });
    await writeAudit(tx, {
      userId: actor.id, action: 'ASSIGN_SUBMISSION', entityType: 'submission', entityId: submission_id,
      details: `Assigned to secretary ${assigned_to}`, ip,
    });
    await notifyUser(tx, assigned_to, submission_id, `You have been assigned submission: '${sub.title}'`);
    await notifyUser(tx, sub.user_id, submission_id,
      `Your submission '${sub.title}' has been assigned for review.`);
    return a;
  });
  const full = await prisma.assignments.findUnique({
    where: { id: assignment.id }, include: { secretary: true, admin: true },
  });
  return { message: 'Submission assigned.', assignment: assignmentDict(full) };
}

export async function listAssignments(user) {
  const where = user.role === 'secretary' ? { assigned_to: user.id } : {};
  const items = await prisma.assignments.findMany({
    where, include: { secretary: true, admin: true }, orderBy: { id: 'asc' },
  });
  return { assignments: items.map(assignmentDict) };
}
