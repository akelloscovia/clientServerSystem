"""
User model — supports roles: user, admin, secretary.
"""
from datetime import datetime, timezone
from ..extensions import db


class User(db.Model):
    __tablename__ = "users"

    id            = db.Column(db.Integer, primary_key=True)
    name          = db.Column(db.String(120), nullable=False)
    email         = db.Column(db.String(180), unique=True, nullable=False, index=True)
    password_hash = db.Column(db.String(256), nullable=False)
    role          = db.Column(
        db.Enum("user", "admin", "secretary", name="user_role"),
        default="user", nullable=False
    )
    is_active     = db.Column(db.Boolean, default=True, nullable=False)
    created_at    = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at    = db.Column(
        db.DateTime,
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc)
    )

    # Relationships
    submissions   = db.relationship("Submission", back_populates="submitter",
                                    foreign_keys="Submission.user_id", lazy="dynamic")
    responses     = db.relationship("Response", back_populates="responder", lazy="dynamic")
    notifications = db.relationship("Notification", back_populates="user", lazy="dynamic")
    assignments   = db.relationship("Assignment", back_populates="secretary",
                                    foreign_keys="Assignment.assigned_to", lazy="dynamic")
    audit_logs    = db.relationship("AuditLog", back_populates="actor", lazy="dynamic")

    def __repr__(self):
        return f"<User {self.email} [{self.role}]>"

    def to_dict(self):
        return {
            "id":         self.id,
            "name":       self.name,
            "email":      self.email,
            "role":       self.role,
            "is_active":  self.is_active,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }
