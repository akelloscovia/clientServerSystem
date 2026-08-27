"""
Channel model — TV channels the reception kiosk can switch between.
Admins can point these at existing live streams or add their own URLs.
"""
from datetime import datetime, timezone
from ..extensions import db

STREAM_TYPES = ["hls", "youtube", "mp4", "other"]


class Channel(db.Model):
    __tablename__ = "channels"

    id          = db.Column(db.Integer, primary_key=True)
    name        = db.Column(db.String(100), nullable=False)
    stream_url  = db.Column(db.String(500), nullable=False)
    logo_url    = db.Column(db.String(500))
    stream_type = db.Column(db.Enum(*STREAM_TYPES, name="channel_stream_type"),
                            default="hls", nullable=False)
    sort_order  = db.Column(db.Integer, default=0, nullable=False)
    is_active   = db.Column(db.Boolean, default=True, nullable=False)
    created_at  = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at  = db.Column(
        db.DateTime,
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc)
    )

    def __repr__(self):
        return f"<Channel {self.id}: {self.name}>"

    def to_dict(self):
        return {
            "id":          self.id,
            "name":        self.name,
            "stream_url":  self.stream_url,
            "logo_url":    self.logo_url,
            "stream_type": self.stream_type,
            "sort_order":  self.sort_order,
            "is_active":   self.is_active,
            "created_at":  self.created_at.isoformat() if self.created_at else None,
            "updated_at":  self.updated_at.isoformat() if self.updated_at else None,
        }
