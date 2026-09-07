import { prisma } from '../db.js';
import { HttpError } from '../utils/httpError.js';
import { visitorDict, visitorReplyDict } from '../utils/serialize.js';
import { parseHHMM, parseDateOnly } from '../utils/dates.js';

const REPLIES_INCLUDE = {
  replies: { include: { responder: true }, orderBy: { created_at: 'asc' } },
  assigned_user: true,
};

async function findOr404(id, include) {
  const v = await prisma.visitor_logs.findUnique({ where: { id }, include });
  if (!v) throw new HttpError(404, 'Resource not found.');
  return v;
}

export async function createVisitor(data) {
  const visitor = await prisma.visitor_logs.create({
    data: {
      name: data.name,
      company: data.company || null,
      visit_date: parseDateOnly(data.visit_date),
      time_in: parseHHMM(data.time_in),
      reason_for_visit: data.reason_for_visit,
      description: data.description || null,
    },
  });
  return {
    status: 201,
    body: { message: 'Thank you. Your visit has been logged.', visitor: visitorDict(visitor) },
  };
}

export async function getVisitors(page = 1, perPage = 20, status) {
  if (page < 1 || perPage < 1 || perPage > 100) {
    throw new HttpError(400, 'page must be >= 1 and per_page must be between 1 and 100.');
  }
  const where = status ? { status } : {};
  const [total, items] = await prisma.$transaction([
    prisma.visitor_logs.count({ where }),
    prisma.visitor_logs.findMany({
      where,
      include: { assigned_user: true },
      orderBy: { created_at: 'desc' },
      skip: (page - 1) * perPage,
      take: perPage,
    }),
  ]);
  return {
    visitors: items.map((v) => visitorDict(v)),
    total,
    pages: total === 0 ? 0 : Math.ceil(total / perPage),
    page,
    per_page: perPage,
  };
}

export async function getVisitor(id) {
  const v = await findOr404(id, REPLIES_INCLUDE);
  return { visitor: visitorDict(v, { includeReplies: true }) };
}

export async function updateVisitorStatus(id, status) {
  await findOr404(id);
  const v = await prisma.visitor_logs.update({
    where: { id }, data: { status }, include: { assigned_user: true },
  });
  return { message: 'Status updated.', visitor: visitorDict(v) };
}

export async function assignVisitor(id, assignedTo, actor) {
  const visitor = await findOr404(id);
  const staff = await prisma.users.findUnique({ where: { id: assignedTo } });
  if (!staff) throw new HttpError(404, 'Resource not found.');
  if (!['secretary', 'admin'].includes(staff.role) || !staff.is_active) {
    throw new HttpError(400, 'Target user is not an active staff member.');
  }
  const v = await prisma.visitor_logs.update({
    where: { id },
    data: {
      assigned_to: assignedTo,
      assigned_by: actor.id,
      assigned_at: new Date(),
      status: visitor.status === 'pending' ? 'assigned' : visitor.status,
    },
    include: { assigned_user: true },
  });
  return { message: 'Visitor assigned.', visitor: visitorDict(v) };
}

export async function deleteVisitor(id) {
  await findOr404(id);
  await prisma.$transaction(async (tx) => {
    await tx.visitor_replies.deleteMany({ where: { visitor_id: id } });
    await tx.visitor_logs.delete({ where: { id } });
  });
  return { message: 'Visitor log deleted.' };
}

export async function addReply(id, responderId, message) {
  await findOr404(id);
  const reply = await prisma.visitor_replies.create({
    data: { visitor_id: id, responder_id: responderId, message },
    include: { responder: true },
  });
  return { status: 201, body: { message: 'Reply added.', reply: visitorReplyDict(reply) } };
}
