import { prisma } from '../db.js';
import { HttpError } from '../utils/httpError.js';
import { notificationDict } from '../utils/serialize.js';
import { notifyUser, writeAudit } from './audit.js';

export async function getNotificationTargets(user) {
  const role = user.role === 'admin' ? 'secretary' : 'admin';
  const users = await prisma.users.findMany({
    where: { role, is_active: true },
    select: { id: true, name: true, email: true, role: true },
    orderBy: { name: 'asc' },
  });
  return { users };
}

export async function sendStaffNotification(user, targetUserId, message, ip) {
  const target = await prisma.users.findUnique({ where: { id: targetUserId } });
  const expectedRole = user.role === 'admin' ? 'secretary' : 'admin';
  if (!target || !target.is_active || target.role !== expectedRole) {
    throw new HttpError(400, `You can only message an active ${expectedRole}.`);
  }
  const text = message.trim();
  if (!text || text.length > 1000) {
    throw new HttpError(400, 'Message is required and must be 1000 characters or fewer.');
  }
  const notification = await prisma.$transaction(async (tx) => {
    const created = await notifyUser(tx, target.id, null, text);
    await writeAudit(tx, {
      userId: user.id,
      action: 'SEND_STAFF_NOTIFICATION',
      entityType: 'notification',
      entityId: created.id,
      details: `Sent to ${target.email}`,
      ip,
    });
    return created;
  });
  return { notification: notificationDict(notification), recipient: target };
}

export async function getNotifications(userId) {
  const notifs = await prisma.notifications.findMany({
    where: { user_id: userId },
    orderBy: [{ created_at: 'desc' }, { id: 'desc' }],
    take: 50,
  });
  const unread = notifs.filter((n) => !n.is_read).length;
  return { notifications: notifs.map(notificationDict), unread_count: unread };
}

export async function markRead(notifId, userId) {
  const notif = await prisma.notifications.findFirst({ where: { id: notifId, user_id: userId } });
  if (!notif) throw new HttpError(404, 'Notification not found.');
  await prisma.notifications.update({ where: { id: notifId }, data: { is_read: true } });
  return { message: 'Marked as read.' };
}

export async function markAllRead(userId) {
  await prisma.notifications.updateMany({
    where: { user_id: userId, is_read: false },
    data: { is_read: true },
  });
  return { message: 'All notifications marked as read.' };
}
