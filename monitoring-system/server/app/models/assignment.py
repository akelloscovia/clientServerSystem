"""
Assignment model — links a submission to a secretary for handling.
Also tracks audit log entries.
"""
from datetime import datetime, timezone
from ..extensions import db


class Assignment(db.Model):
    __tablename__ = "assignments"

    id            = db.Column(db.Integer, primary_key=True)
    submission_id = db.Column(db.Integer, db.ForeignKey("submissions.id"),
                              nullable=False, unique=True)
    assigned_to   = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    assigned_by   = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    notes         = db.Column(db.Text)
    assigned_at   = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))

    # Relationships
    submission = db.relationship("Submission", back_populates="assignment")
    secretary  = db.relationship("User", back_populates="assignments",
                                 foreign_keys=[assigned_to])
    admin      = db.relationship("User", foreign_keys=[assigned_by])

    def __repr__(self):
        return f"<Assignment sub={self.submission_id} → user={self.assigned_to}>"

    def to_dict(self):
        return {
            "id":            self.id,
            "submission_id": self.submission_id,
            "assigned_to":   self.assigned_to,
            "secretary":     self.secretary.name if self.secretary else None,
            "assigned_by":   self.assigned_by,
            "admin":         self.admin.name if self.admin else None,
            "notes":         self.notes,
            "assigned_at":   self.assigned_at.isoformat() if self.assigned_at else None,
        }


class AuditLog(db.Model):
    __tablename__ = "audit_logs"

    id          = db.Column(db.Integer, primary_key=True)
    user_id     = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=True)
    action      = db.Column(db.String(100), nullable=False)
    entity_type = db.Column(db.String(50))
    entity_id   = db.Column(db.Integer)
    details     = db.Column(db.Text)
    ip_address  = db.Column(db.String(45))
    timestamp   = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc), index=True)

    # Relationships
    actor = db.relationship("User", back_populates="audit_logs")

    def to_dict(self):
        return {
            "id":          self.id,
            "user_id":     self.user_id,
            "actor":       self.actor.name if self.actor else "System",
            "action":      self.action,
            "entity_type": self.entity_type,
            "entity_id":   self.entity_id,
            "details":     self.details,
            "ip_address":  self.ip_address,
            "timestamp":   self.timestamp.isoformat() if self.timestamp else None,
        }
