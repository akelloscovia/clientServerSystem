"""Immutable status changes for submission audit and elapsed-time reporting."""
from datetime import datetime, timezone
from ..extensions import db


class SubmissionStatusHistory(db.Model):
    __tablename__ = "submission_status_history"

    id = db.Column(db.Integer, primary_key=True)
    submission_id = db.Column(db.Integer, db.ForeignKey("submissions.id"), nullable=False, index=True)
    changed_by = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=True)
    from_status = db.Column(db.String(30), nullable=True)
    to_status = db.Column(db.String(30), nullable=False)
    changed_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc), nullable=False, index=True)

    submission = db.relationship("Submission", back_populates="status_history")
    actor = db.relationship("User")

    def to_dict(self):
        return {
            "id": self.id,
            "submission_id": self.submission_id,
            "changed_by": self.changed_by,
            "actor": self.actor.name if self.actor else "System",
            "from_status": self.from_status,
            "to_status": self.to_status,
            "changed_at": self.changed_at.isoformat() if self.changed_at else None,
        }