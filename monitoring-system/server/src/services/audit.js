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

/** Create an in-app notification (old notification_service.notify_user). */
export function notifyUser(client, userId, submissionId, message) {
  return client.notifications.create({
    data: { user_id: userId, submission_id: submissionId ?? null, message },
  });
}
