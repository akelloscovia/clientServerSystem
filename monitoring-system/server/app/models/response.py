"""
Response model — admin/secretary replies attached to a submission.
"""
from datetime import datetime, timezone
from ..extensions import db


class Response(db.Model):
    __tablename__ = "responses"

    id            = db.Column(db.Integer, primary_key=True)
    submission_id = db.Column(db.Integer, db.ForeignKey("submissions.id"),
                              nullable=False, index=True)
    responder_id  = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    message       = db.Column(db.Text, nullable=False)
    created_at    = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))

    # Relationships
    submission = db.relationship("Submission", back_populates="responses")
    responder  = db.relationship("User", back_populates="responses")

    def __repr__(self):
        return f"<Response {self.id} on Submission {self.submission_id}>"

    def to_dict(self):
        return {
            "id":            self.id,
            "submission_id": self.submission_id,
            "responder_id":  self.responder_id,
            "responder":     self.responder.name if self.responder else None,
            "responder_role": self.responder.role if self.responder else None,
            "message":       self.message,
            "created_at":    self.created_at.isoformat() if self.created_at else None,
        }
