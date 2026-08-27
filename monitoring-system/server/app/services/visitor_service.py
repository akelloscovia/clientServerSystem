"""
Visitor log service — CRUD, assignment and replies.
Kept independent from the case-submission service by design.
"""
from datetime import datetime, timezone
from ..extensions import db
from ..models.visitor_log import VisitorLog, VisitorReply
from ..models.user import User


def create_visitor(data: dict) -> tuple[dict, int]:
    visitor = VisitorLog(
        name=data["name"],
        company=data.get("company") or None,
        visit_date=data["visit_date"],
        time_in=data["time_in"],
        reason_for_visit=data["reason_for_visit"],
        description=data.get("description") or None,
    )
    db.session.add(visitor)
    db.session.commit()
    return {"message": "Thank you. Your visit has been logged.", "visitor": visitor.to_dict()}, 201


def get_visitors(page: int = 1, per_page: int = 20, status: str = None) -> tuple[dict, int]:
    if page < 1 or per_page < 1 or per_page > 100:
        return {"error": "page must be >= 1 and per_page must be between 1 and 100."}, 400
    query = VisitorLog.query
    if status:
        query = query.filter_by(status=status)
    paginated = query.order_by(VisitorLog.created_at.desc()).paginate(
        page=page, per_page=per_page, error_out=False
    )
    return {
        "visitors": [v.to_dict() for v in paginated.items],
        "total":    paginated.total,
        "pages":    paginated.pages,
        "page":     page,
        "per_page": per_page,
    }, 200


def get_visitor(visitor_id: int) -> tuple[dict, int]:
    visitor = VisitorLog.query.get_or_404(visitor_id)
    return {"visitor": visitor.to_dict(include_replies=True)}, 200


def update_visitor_status(visitor_id: int, status: str) -> tuple[dict, int]:
    visitor = VisitorLog.query.get_or_404(visitor_id)
    visitor.status = status
    db.session.commit()
    return {"message": "Status updated.", "visitor": visitor.to_dict()}, 200


def assign_visitor(visitor_id: int, assigned_to: int, actor: User) -> tuple[dict, int]:
    visitor = VisitorLog.query.get_or_404(visitor_id)
    staff = User.query.get_or_404(assigned_to)
    if staff.role not in ("secretary", "admin") or not staff.is_active:
        return {"error": "Target user is not an active staff member."}, 400

    visitor.assigned_to = assigned_to
    visitor.assigned_by = actor.id
    visitor.assigned_at = datetime.now(timezone.utc)
    if visitor.status == "pending":
        visitor.status = "assigned"
    db.session.commit()
    return {"message": "Visitor assigned.", "visitor": visitor.to_dict()}, 200


def delete_visitor(visitor_id: int) -> tuple[dict, int]:
    visitor = VisitorLog.query.get_or_404(visitor_id)
    db.session.delete(visitor)
    db.session.commit()
    return {"message": "Visitor log deleted."}, 200


def add_reply(visitor_id: int, responder_id: int, message: str) -> tuple[dict, int]:
    visitor = VisitorLog.query.get_or_404(visitor_id)
    reply = VisitorReply(visitor_id=visitor.id, responder_id=responder_id, message=message)
    db.session.add(reply)
    db.session.commit()
    return {"message": "Reply added.", "reply": reply.to_dict()}, 201
