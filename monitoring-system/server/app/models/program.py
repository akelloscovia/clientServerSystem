"""
Program model — the ministry's daily schedule shown on the reception kiosk.
"""
from datetime import datetime, timezone
from ..extensions import db

DAYS = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday", "daily"]


class Program(db.Model):
    __tablename__ = "programs"

    id          = db.Column(db.Integer, primary_key=True)
    title       = db.Column(db.String(200), nullable=False)
    description = db.Column(db.Text)
    day         = db.Column(db.Enum(*DAYS, name="program_day"), default="daily", nullable=False)
    start_time  = db.Column(db.Time, nullable=False)
    end_time    = db.Column(db.Time, nullable=False)
    location    = db.Column(db.String(200))
    is_active   = db.Column(db.Boolean, default=True, nullable=False)
    created_at  = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at  = db.Column(
        db.DateTime,
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc)
    )

    def __repr__(self):
        return f"<Program {self.id}: {self.title} [{self.day}]>"

    def to_dict(self):
        return {
            "id":          self.id,
            "title":       self.title,
            "description": self.description,
            "day":         self.day,
            "start_time":  self.start_time.strftime("%H:%M") if self.start_time else None,
            "end_time":    self.end_time.strftime("%H:%M") if self.end_time else None,
            "location":    self.location,
            "is_active":   self.is_active,
            "created_at":  self.created_at.isoformat() if self.created_at else None,
            "updated_at":  self.updated_at.isoformat() if self.updated_at else None,
        }
