"""
Submission service — CRUD + status management.
"""
from ..extensions import db
from ..models.submission import Submission
from ..models.user import User
from ..models.assignment import Assignment, AuditLog
from .notification_service import notify_user
from flask import request
from datetime import datetime
from sqlalchemy import or_
from ..models.status_history import SubmissionStatusHistory

STATUS_TRANSITIONS = {
    "pending": {"under_review", "assigned"},
    "under_review": {"assigned", "resolved"},
    "assigned": {"under_review", "resolved"},
    "resolved": {"closed"},
    "closed": set(),
}


def _audit(user_id, action, entity_id=None, details=None):
    log = AuditLog(user_id=user_id, action=action,
                   entity_type="submission", entity_id=entity_id,
                   details=details, ip_address=request.remote_addr)
    db.session.add(log)


def create_submission(user_id: int, data: dict) -> tuple[dict, int]:
    sub = Submission(
        user_id=user_id,
        title=data["title"],
        description=data["description"],
        category=data.get("category", "other"),
        priority=data.get("priority", "medium"),
    )
    db.session.add(sub)
    db.session.flush()
    db.session.add(SubmissionStatusHistory(
        submission_id=sub.id, changed_by=user_id, from_status=None, to_status=sub.status
    ))
    _audit(user_id, "CREATE_SUBMISSION", sub.id, f"Title: {sub.title}")

    # Notify all admins
    admins = User.query.filter_by(role="admin", is_active=True).all()
    for admin in admins:
        notify_user(admin.id, sub.id,
                    f"New submission: '{sub.title}' from {sub.submitter.name if sub.submitter else 'user'}")

    db.session.commit()
    return {"message": "Submission created.", "submission": sub.to_dict()}, 201


def get_submissions(user: User, page: int = 1, per_page: int = 20,
                    status: str = None, category: str = None,
                    priority: str = None, search: str = None,
                    date_from: str = None, date_to: str = None,
                    assigned_to: int = None) -> tuple[dict, int]:
    query = Submission.query
    if user.role == "user":
        query = query.filter_by(user_id=user.id)
    elif user.role == "secretary":
        # Only assigned submissions
        assigned_ids = [a.submission_id for a in user.assignments.all()]
        query = query.filter(Submission.id.in_(assigned_ids))
    # admin sees all
    if status:
        query = query.filter_by(status=status)
    if category:
        query = query.filter_by(category=category)
    if priority:
        query = query.filter_by(priority=priority)
    if assigned_to:
        query = query.join(Assignment, Assignment.submission_id == Submission.id)
        query = query.filter(Assignment.assigned_to == assigned_to)
    if search:
        term = f"%{search.strip()}%"
        query = query.filter(or_(Submission.title.ilike(term), Submission.description.ilike(term)))
    if date_from:
        try:
            query = query.filter(Submission.created_at >= datetime.fromisoformat(date_from))
        except ValueError:
            return {"error": "Invalid 'from' date. Use ISO-8601 format."}, 400
    if date_to:
        try:
            query = query.filter(Submission.created_at <= datetime.fromisoformat(date_to))
        except ValueError:
            return {"error": "Invalid 'to' date. Use ISO-8601 format."}, 400

    if page < 1 or per_page < 1 or per_page > 100:
        return {"error": "page must be >= 1 and per_page must be between 1 and 100."}, 400

    # FIFO queue: older submissions are attended to first; id breaks timestamp ties.
    paginated = query.order_by(Submission.created_at.asc(), Submission.id.asc()).paginate(
        page=page, per_page=per_page, error_out=False
    )
    return {
        "submissions": [s.to_dict() for s in paginated.items],
        "total":   paginated.total,
        "pages":   paginated.pages,
        "page":    page,
        "per_page": per_page,
    }, 200


def get_submission(sub_id: int, user: User) -> tuple[dict, int]:
    sub = Submission.query.get_or_404(sub_id)
    # Access control
    if user.role == "user" and sub.user_id != user.id:
        return {"error": "Access denied."}, 403
    if user.role == "secretary":
        assigned = Assignment.query.filter_by(
            submission_id=sub_id, assigned_to=user.id).first()
        if not assigned:
            return {"error": "Access denied."}, 403
    return {"submission": sub.to_dict(include_responses=True)}, 200


def update_status(sub_id: int, new_status: str, actor: User) -> tuple[dict, int]:
    sub = Submission.query.get_or_404(sub_id)
    old_status = sub.status
    if actor.role == "secretary" and not Assignment.query.filter_by(
            submission_id=sub_id, assigned_to=actor.id).first():
        return {"error": "You can only update submissions assigned to you."}, 403
    if new_status == old_status:
        return {"error": "Submission is already in that status."}, 409
    if new_status not in STATUS_TRANSITIONS.get(old_status, set()):
        return {"error": f"Invalid status transition from '{old_status}' to '{new_status}'."}, 409
    sub.status = new_status
    db.session.add(SubmissionStatusHistory(submission_id=sub.id, changed_by=actor.id,
                                           from_status=old_status, to_status=new_status))
    _audit(actor.id, "UPDATE_STATUS", sub.id,
           f"{old_status} → {new_status}")
    # Notify submitter
    notify_user(sub.user_id, sub.id,
                f"Your submission '{sub.title}' status changed to '{new_status}'.")
    db.session.commit()
    return {"message": "Status updated.", "submission": sub.to_dict()}, 200


def delete_submission(sub_id: int, actor: User) -> tuple[dict, int]:
    sub = Submission.query.get_or_404(sub_id)
    _audit(actor.id, "DELETE_SUBMISSION", sub_id, f"Deleted: {sub.title}")
    db.session.delete(sub)
    db.session.commit()
    return {"message": "Submission deleted."}, 200


def assign_submission(data: dict, actor: User) -> tuple[dict, int]:
    sub_id   = data["submission_id"]
    sec_id   = data["assigned_to"]
    notes    = data.get("notes", "")

    sub = Submission.query.get_or_404(sub_id)
    secretary = User.query.get_or_404(sec_id)
    if secretary.role != "secretary" or not secretary.is_active:
        return {"error": "Target user is not a secretary."}, 400

    # Remove old assignment if exists
    old = Assignment.query.filter_by(submission_id=sub_id).first()
    if old:
        db.session.delete(old)

    assignment = Assignment(
        submission_id=sub_id,
        assigned_to=sec_id,
        assigned_by=actor.id,
        notes=notes,
    )
    old_status = sub.status
    sub.status = "assigned"
    db.session.add(SubmissionStatusHistory(submission_id=sub.id, changed_by=actor.id,
                                           from_status=old_status, to_status="assigned"))
    db.session.add(assignment)
    db.session.flush()
    _audit(actor.id, "ASSIGN_SUBMISSION", sub_id,
           f"Assigned to secretary {sec_id}")
    notify_user(sec_id, sub_id,
                f"You have been assigned submission: '{sub.title}'")
    notify_user(sub.user_id, sub_id,
                f"Your submission '{sub.title}' has been assigned for review.")
    db.session.commit()
    return {"message": "Submission assigned.", "assignment": assignment.to_dict()}, 200


def get_status_history(sub_id: int, user: User) -> tuple[dict, int]:
    sub = Submission.query.get_or_404(sub_id)
    if user.role == "user" and sub.user_id != user.id:
        return {"error": "Access denied."}, 403
    if user.role == "secretary" and not Assignment.query.filter_by(
            submission_id=sub_id, assigned_to=user.id).first():
        return {"error": "Access denied."}, 403
    return {"status_history": [item.to_dict() for item in sub.status_history]}, 200
