"""
Monitoring service — dashboard statistics and audit logs.
"""
from sqlalchemy import func
from ..extensions import db
from ..models.submission import Submission
from ..models.user import User
from ..models.assignment import AuditLog
from ..models.program import Program
from ..models.visitor_log import VisitorLog, VISITOR_STATUSES


def get_stats() -> tuple[dict, int]:
    """Return high-level dashboard statistics."""
    total         = Submission.query.count()
    pending       = Submission.query.filter_by(status="pending").count()
    under_review  = Submission.query.filter_by(status="under_review").count()
    assigned      = Submission.query.filter_by(status="assigned").count()
    resolved      = Submission.query.filter_by(status="resolved").count()
    closed        = Submission.query.filter_by(status="closed").count()
    total_users   = User.query.filter_by(role="user").count()
    secretaries   = User.query.filter_by(role="secretary", is_active=True).count()
    total_staff   = User.query.filter(User.role.in_(["admin", "secretary"])).count()

    # Submissions by category
    by_category = (
        db.session.query(Submission.category, func.count(Submission.id))
        .group_by(Submission.category)
        .all()
    )
    # Submissions by priority
    by_priority = (
        db.session.query(Submission.priority, func.count(Submission.id))
        .group_by(Submission.priority)
        .all()
    )
    # Last 7 days volume (daily counts)
    from datetime import datetime, timedelta, timezone
    today = datetime.now(timezone.utc).date()
    daily = []
    for i in range(6, -1, -1):
        day = today - timedelta(days=i)
        count = Submission.query.filter(
            func.date(Submission.created_at) == day
        ).count()
        daily.append({"date": day.isoformat(), "count": count})

    # Visitor log breakdown by status
    visitor_counts = {s: 0 for s in VISITOR_STATUSES}
    for status, cnt in (
        db.session.query(VisitorLog.status, func.count(VisitorLog.id))
        .group_by(VisitorLog.status)
        .all()
    ):
        visitor_counts[status] = cnt
    visitor_counts["total"] = sum(visitor_counts[s] for s in VISITOR_STATUSES)
    visitors_today = VisitorLog.query.filter(
        func.date(VisitorLog.created_at) == today
    ).count()
    visitor_counts["today"] = visitors_today

    return {
        "overview": {
            "total":        total,
            "pending":      pending,
            "under_review": under_review,
            "assigned":     assigned,
            "resolved":     resolved,
            "closed":       closed,
            "total_users":  total_users,
            "secretaries":  secretaries,
            "total_staff": total_staff,
        },
        "by_category": {cat: cnt for cat, cnt in by_category},
        "by_priority":  {pri: cnt for pri, cnt in by_priority},
        "daily_trend":  daily,
        "visitors": visitor_counts,
        "programs": {
            "active": Program.query.filter_by(is_active=True).count(),
            "total":  Program.query.count(),
        },
        "queue": {
            "oldest_pending": Submission.query.filter_by(status="pending")
                .order_by(Submission.created_at.asc(), Submission.id.asc()).first().to_dict()
                if Submission.query.filter_by(status="pending").first() else None,
        },
    }, 200


def get_audit_logs(page: int = 1, per_page: int = 50) -> tuple[dict, int]:
    paginated = (AuditLog.query
                 .order_by(AuditLog.timestamp.desc())
                 .paginate(page=page, per_page=per_page, error_out=False))
    return {
        "logs":     [log.to_dict() for log in paginated.items],
        "total":    paginated.total,
        "pages":    paginated.pages,
        "page":     page,
        "per_page": per_page,
    }, 200
