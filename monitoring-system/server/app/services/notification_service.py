"""
Notification service — create and retrieve notifications.
"""
from ..extensions import db
from ..models.notification import Notification


def notify_user(user_id: int, submission_id: int | None, message: str):
    """Create a notification for a user (call before db.session.commit)."""
    notif = Notification(
        user_id=user_id,
        submission_id=submission_id,
        message=message,
    )
    db.session.add(notif)


def get_notifications(user_id: int) -> tuple[dict, int]:
    notifs = (Notification.query
              .filter_by(user_id=user_id)
              .order_by(Notification.created_at.desc())
              .limit(50)
              .all())
    unread = sum(1 for n in notifs if not n.is_read)
    return {
        "notifications": [n.to_dict() for n in notifs],
        "unread_count":  unread,
    }, 200


def mark_read(notif_id: int, user_id: int) -> tuple[dict, int]:
    notif = Notification.query.filter_by(id=notif_id, user_id=user_id).first()
    if not notif:
        return {"error": "Notification not found."}, 404
    notif.is_read = True
    db.session.commit()
    return {"message": "Marked as read."}, 200


def mark_all_read(user_id: int) -> tuple[dict, int]:
    (Notification.query
     .filter_by(user_id=user_id, is_read=False)
     .update({"is_read": True}))
    db.session.commit()
    return {"message": "All notifications marked as read."}, 200
