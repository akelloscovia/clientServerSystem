/**
 * Append an audit-log row. Pass a Prisma client or a transaction client as
 * `client` so the write joins the surrounding transaction (mirrors the old
 * `_audit()` helpers that added to the session before commit).
 */
export function writeAudit(client, { userId = null, action, entityType = null, entityId = null, details = null, ip = null }) {
  return client.audit_logs.create({
    data: {
      user_id: userId,
      action,
      entity_type: entityType,
      entity_id: entityId,
      details,
      ip_address: ip,
    },
  });
}

import { config } from '../config.js';
import { notificationDict } from '../utils/serialize.js';
import Pusher from 'pusher';

let pusher;
function getPusher() {
  if (!config.pusher.appId || !config.pusher.key || !config.pusher.secret) return null;
  if (!pusher) {
    pusher = new Pusher({
      appId: config.pusher.appId,
      key: config.pusher.key,
      secret: config.pusher.secret,
      cluster: config.pusher.cluster,
      useTLS: true,
    });
  }
  return pusher;
}

export function userNotificationChannel(userId) {
  return `private-user-${userId}`;
}

/** Create an in-app notification and publish the same payload to Pusher. */
export async function notifyUser(client, userId, submissionId, message) {
  const notification = await client.notifications.create({
    data: { user_id: userId, submission_id: submissionId ?? null, message },
  });
  const clientPusher = getPusher();
  if (clientPusher) {
    clientPusher.trigger(userNotificationChannel(userId), 'notification.created', {
      notification: notificationDict(notification),
    }).catch((error) => console.error('Pusher notification failed:', error.message));
  }
  return notification;
}
