"""
Channel service — CRUD for kiosk TV channels.
"""
from ..extensions import db
from ..models.channel import Channel


def list_channels(active_only: bool = True) -> tuple[dict, int]:
    query = Channel.query
    if active_only:
        query = query.filter_by(is_active=True)
    channels = query.order_by(Channel.sort_order.asc(), Channel.id.asc()).all()
    return {"channels": [c.to_dict() for c in channels]}, 200


def create_channel(data: dict) -> tuple[dict, int]:
    channel = Channel(**data)
    db.session.add(channel)
    db.session.commit()
    return {"message": "Channel added.", "channel": channel.to_dict()}, 201


def update_channel(channel_id: int, data: dict) -> tuple[dict, int]:
    channel = Channel.query.get_or_404(channel_id)
    for key, value in data.items():
        setattr(channel, key, value)
    db.session.commit()
    return {"message": "Channel updated.", "channel": channel.to_dict()}, 200


def delete_channel(channel_id: int) -> tuple[dict, int]:
    channel = Channel.query.get_or_404(channel_id)
    db.session.delete(channel)
    db.session.commit()
    return {"message": "Channel deleted."}, 200
