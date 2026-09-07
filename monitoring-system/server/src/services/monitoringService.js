import { prisma } from '../db.js';
import { submissionDict, auditLogDict } from '../utils/serialize.js';

const VISITOR_STATUSES = ['pending', 'assigned', 'attended', 'closed'];

function dayRangeUTC(date) {
  const start = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));
  const end = new Date(start.getTime() + 24 * 60 * 60 * 1000);
  return { start, end };
}

export async function getStats() {
  const [total, pending, under_review, assigned, resolved, closed] = await Promise.all([
    prisma.submissions.count(),
    prisma.submissions.count({ where: { status: 'pending' } }),
    prisma.submissions.count({ where: { status: 'under_review' } }),
    prisma.submissions.count({ where: { status: 'assigned' } }),
    prisma.submissions.count({ where: { status: 'resolved' } }),
    prisma.submissions.count({ where: { status: 'closed' } }),
  ]);

  const [total_users, secretaries, total_staff] = await Promise.all([
    prisma.users.count({ where: { role: 'user' } }),
    prisma.users.count({ where: { role: 'secretary', is_active: true } }),
    prisma.users.count({ where: { role: { in: ['admin', 'secretary'] } } }),
  ]);

  const catGroups = await prisma.submissions.groupBy({ by: ['category'], _count: { id: true } });
  const priGroups = await prisma.submissions.groupBy({ by: ['priority'], _count: { id: true } });
  const by_category = Object.fromEntries(catGroups.map((g) => [g.category, g._count.id]));
  const by_priority = Object.fromEntries(priGroups.map((g) => [g.priority, g._count.id]));

  const now = new Date();
  const daily = [];
  for (let i = 6; i >= 0; i -= 1) {
    const d = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() - i));
    const { start, end } = dayRangeUTC(d);
    // eslint-disable-next-line no-await-in-loop
    const count = await prisma.submissions.count({ where: { created_at: { gte: start, lt: end } } });
    daily.push({ date: start.toISOString().slice(0, 10), count });
  }

  const vGroups = await prisma.visitor_logs.groupBy({ by: ['status'], _count: { id: true } });
  const visitors = Object.fromEntries(VISITOR_STATUSES.map((s) => [s, 0]));
  for (const g of vGroups) visitors[g.status] = g._count.id;
  visitors.total = VISITOR_STATUSES.reduce((sum, s) => sum + visitors[s], 0);
  const todayRange = dayRangeUTC(now);
  visitors.today = await prisma.visitor_logs.count({
    where: { created_at: { gte: todayRange.start, lt: todayRange.end } },
  });

  const [programsActive, programsTotal] = await Promise.all([
    prisma.programs.count({ where: { is_active: true } }),
    prisma.programs.count(),
  ]);

  const oldest = await prisma.submissions.findFirst({
    where: { status: 'pending' },
    orderBy: [{ created_at: 'asc' }, { id: 'asc' }],
    include: { submitter: true },
  });

  return {
    overview: {
      total, pending, under_review, assigned, resolved, closed,
      total_users, secretaries, total_staff,
    },
    by_category,
    by_priority,
    daily_trend: daily,
    visitors,
    programs: { active: programsActive, total: programsTotal },
    queue: { oldest_pending: oldest ? submissionDict(oldest) : null },
  };
}

export async function getAuditLogs(page = 1, perPage = 50) {
  const [total, items] = await prisma.$transaction([
    prisma.audit_logs.count(),
    prisma.audit_logs.findMany({
      include: { actor: true },
      orderBy: { timestamp: 'desc' },
      skip: (page - 1) * perPage,
      take: perPage,
    }),
  ]);
  return {
    logs: items.map(auditLogDict),
    total,
    pages: total === 0 ? 0 : Math.ceil(total / perPage),
    page,
    per_page: perPage,
  };
}
