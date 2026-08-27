"""
Visitor log — a separate module from case submissions. Walk-in visitors fill
this in (via the QR code shown on the reception kiosk); staff can view,
assign, reply to, and delete entries from the dashboard.
"""
from datetime import datetime, timezone
from ..extensions import db

VISITOR_STATUSES = ["pending", "assigned", "attended", "closed"]


class VisitorLog(db.Model):
    __tablename__ = "visitor_logs"

    id                = db.Column(db.Integer, primary_key=True)
    name              = db.Column(db.String(150), nullable=False)
    company           = db.Column(db.String(150))
    visit_date        = db.Column(db.Date, nullable=False)
    time_in           = db.Column(db.Time, nullable=False)
    reason_for_visit  = db.Column(db.String(300), nullable=False)
    description       = db.Column(db.Text)
    status            = db.Column(db.Enum(*VISITOR_STATUSES, name="visitor_status"),
                                  default="pending", nullable=False)
    assigned_to       = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=True)
    assigned_by       = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=True)
    assigned_at       = db.Column(db.DateTime)
    created_at        = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc), index=True)
    updated_at        = db.Column(
        db.DateTime,
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc)
    )

    assignee = db.relationship("User", foreign_keys=[assigned_to])
    assigner = db.relationship("User", foreign_keys=[assigned_by])
    replies  = db.relationship("VisitorReply", back_populates="visitor",
                               cascade="all, delete-orphan",
                               order_by="VisitorReply.created_at.asc()")

    def __repr__(self):
        return f"<VisitorLog {self.id}: {self.name} [{self.status}]>"

    def to_dict(self, include_replies=False):
        data = {
            "id":               self.id,
            "name":             self.name,
            "company":          self.company,
            "visit_date":       self.visit_date.isoformat() if self.visit_date else None,
            "time_in":          self.time_in.strftime("%H:%M") if self.time_in else None,
            "reason_for_visit": self.reason_for_visit,
            "description":      self.description,
            "status":           self.status,
            "assigned_to":      self.assigned_to,
            "assignee":         self.assignee.name if self.assignee else None,
            "assigned_by":      self.assigned_by,
            "assigned_at":      self.assigned_at.isoformat() if self.assigned_at else None,
            "created_at":       self.created_at.isoformat() if self.created_at else None,
            "updated_at":       self.updated_at.isoformat() if self.updated_at else None,
        }
        if include_replies:
            data["replies"] = [r.to_dict() for r in self.replies]
        return data


class VisitorReply(db.Model):
    __tablename__ = "visitor_replies"

    id           = db.Column(db.Integer, primary_key=True)
    visitor_id   = db.Column(db.Integer, db.ForeignKey("visitor_logs.id"),
                             nullable=False, index=True)
    responder_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    message      = db.Column(db.Text, nullable=False)
    created_at   = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))

    visitor   = db.relationship("VisitorLog", back_populates="replies")
    responder = db.relationship("User")

    def __repr__(self):
        return f"<VisitorReply {self.id} on VisitorLog {self.visitor_id}>"

    def to_dict(self):
        return {
            "id":           self.id,
            "visitor_id":   self.visitor_id,
            "responder_id": self.responder_id,
            "responder":    self.responder.name if self.responder else None,
            "message":      self.message,
            "created_at":   self.created_at.isoformat() if self.created_at else None,
        }
