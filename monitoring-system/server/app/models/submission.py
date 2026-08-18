"""
Submission model — core entity representing a user's submitted case.
"""
from datetime import datetime, timezone
from ..extensions import db


class Submission(db.Model):
    __tablename__ = "submissions"

    id          = db.Column(db.Integer, primary_key=True)
    user_id     = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False, index=True)
    title       = db.Column(db.String(200), nullable=False)
    description = db.Column(db.Text, nullable=False)
    category    = db.Column(
        db.Enum("complaint", "inquiry", "report", "request", "other", name="submission_category"),
        default="other", nullable=False
    )
    priority    = db.Column(
        db.Enum("low", "medium", "high", "urgent", name="submission_priority"),
        default="medium", nullable=False
    )
    status      = db.Column(
        db.Enum("pending", "under_review", "assigned", "resolved", "closed", name="submission_status"),
        default="pending", nullable=False
    )
    created_at  = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc), index=True)
    updated_at  = db.Column(
        db.DateTime,
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc)
    )

    # Relationships
    submitter   = db.relationship("User", back_populates="submissions",
                                  foreign_keys=[user_id])
    responses   = db.relationship("Response", back_populates="submission",
                                  cascade="all, delete-orphan", lazy="dynamic")
    assignment  = db.relationship("Assignment", back_populates="submission",
                                  uselist=False, cascade="all, delete-orphan")
    notifications = db.relationship("Notification", back_populates="submission",
                                    cascade="all, delete-orphan", lazy="dynamic")

    def __repr__(self):
        return f"<Submission {self.id}: {self.title[:30]} [{self.status}]>"

    def to_dict(self, include_responses=False):
        data = {
            "id":          self.id,
            "user_id":     self.user_id,
            "submitter":   self.submitter.name if self.submitter else None,
            "title":       self.title,
            "description": self.description,
            "category":    self.category,
            "priority":    self.priority,
            "status":      self.status,
            "created_at":  self.created_at.isoformat() if self.created_at else None,
            "updated_at":  self.updated_at.isoformat() if self.updated_at else None,
        }
        if include_responses:
            data["responses"] = [r.to_dict() for r in self.responses.all()]
        return data
