"""
User model — supports roles: user, admin, secretary.
"""
from datetime import datetime, timezone, timedelta
from ..extensions import db


def _utcnow() -> datetime:
    """Naive UTC — matches how the DateTime columns round-trip through MariaDB."""
    return datetime.now(timezone.utc).replace(tzinfo=None)


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

    # Brute-force lockout state (see app/services/auth_service.login_user).
    failed_login_attempts = db.Column(db.Integer, default=0, nullable=False)
    locked_until          = db.Column(db.DateTime, nullable=True)

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

    # --- Login lockout helpers -------------------------------------------------
    def is_locked(self) -> bool:
        return self.locked_until is not None and _utcnow() < self.locked_until

    def lockout_minutes_remaining(self) -> int:
        if not self.is_locked():
            return 0
        return max(1, int((self.locked_until - _utcnow()).total_seconds() // 60) + 1)

    def record_failed_login(self, max_attempts: int, lockout_minutes: int) -> None:
        """Count a failed attempt and lock the account once the limit is hit."""
        self.failed_login_attempts = (self.failed_login_attempts or 0) + 1
        if self.failed_login_attempts >= max_attempts:
            self.locked_until = _utcnow() + timedelta(minutes=lockout_minutes)

    def reset_lockout(self) -> None:
        self.failed_login_attempts = 0
        self.locked_until = None

    def to_dict(self):
        return {
            "id":         self.id,
            "name":       self.name,
            "email":      self.email,
            "role":       self.role,
            "is_active":  self.is_active,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }
