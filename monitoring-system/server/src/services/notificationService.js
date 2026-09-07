import { prisma } from '../db.js';
import { HttpError } from '../utils/httpError.js';
import { notificationDict } from '../utils/serialize.js';

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
