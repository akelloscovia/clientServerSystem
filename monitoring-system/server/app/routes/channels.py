"""
Channel routes — /api/channels

Listing is public so the reception kiosk can fetch the channel list without
logging in. Admins manage the list — pick from what's there or add new URLs.
"""
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required
from marshmallow import ValidationError
from ..schemas.channel_schema import ChannelSchema
from ..services.channel_service import list_channels, create_channel, update_channel, delete_channel
from ..utils.permissions import admin_required

channels_bp = Blueprint("channels", __name__)


@channels_bp.get("/")
def list_all():
    active_only = request.args.get("all") != "1"
    result, code = list_channels(active_only)
    return jsonify(result), code


@channels_bp.post("/")
@jwt_required()
@admin_required
def create():
    data = request.get_json(silent=True) or {}
    try:
        clean = ChannelSchema().load(data)
    except ValidationError as e:
        return jsonify({"errors": e.messages}), 422
    result, status = create_channel(clean)
    return jsonify(result), status


@channels_bp.put("/<int:channel_id>")
@jwt_required()
@admin_required
def update(channel_id):
    data = request.get_json(silent=True) or {}
    try:
        clean = ChannelSchema().load(data)
    except ValidationError as e:
        return jsonify({"errors": e.messages}), 422
    result, code = update_channel(channel_id, clean)
    return jsonify(result), code


@channels_bp.delete("/<int:channel_id>")
@jwt_required()
@admin_required
def delete(channel_id):
    result, code = delete_channel(channel_id)
    return jsonify(result), code
