"""
Notification model — in-app notifications for users.
"""
from datetime import datetime, timezone
from ..extensions import db


class Notification(db.Model):
    __tablename__ = "notifications"

    id            = db.Column(db.Integer, primary_key=True)
    user_id       = db.Column(db.Integer, db.ForeignKey("users.id"),
                              nullable=False, index=True)
    submission_id = db.Column(db.Integer, db.ForeignKey("submissions.id"),
                              nullable=True)
    message       = db.Column(db.String(500), nullable=False)
    is_read       = db.Column(db.Boolean, default=False, nullable=False)
    created_at    = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))

    # Relationships
    user       = db.relationship("User", back_populates="notifications")
    submission = db.relationship("Submission", back_populates="notifications")

    def __repr__(self):
        return f"<Notification {self.id} for user={self.user_id}>"

    def to_dict(self):
        return {
            "id":            self.id,
            "user_id":       self.user_id,
            "submission_id": self.submission_id,
            "message":       self.message,
            "is_read":       self.is_read,
            "created_at":    self.created_at.isoformat() if self.created_at else None,
        }
