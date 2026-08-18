"""
Monitoring routes — /api/monitoring
Dashboard stats, audit logs, notifications.
"""
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from ..services.monitoring_service import get_stats, get_audit_logs
from ..services.notification_service import (
    get_notifications, mark_read, mark_all_read
)
from ..utils.permissions import admin_required, active_user_required

monitoring_bp = Blueprint("monitoring", __name__)


@monitoring_bp.get("/stats")
@jwt_required()
@admin_required
def stats():
    result, code = get_stats()
    return jsonify(result), code


@monitoring_bp.get("/audit-logs")
@jwt_required()
@admin_required
def audit_logs():
    page     = request.args.get("page", 1, type=int)
    per_page = request.args.get("per_page", 50, type=int)
    result, code = get_audit_logs(page, per_page)
    return jsonify(result), code


@monitoring_bp.get("/notifications")
@jwt_required()
@active_user_required
def notifications():
    user_id = get_jwt_identity()
    result, code = get_notifications(user_id)
    return jsonify(result), code


@monitoring_bp.patch("/notifications/<int:notif_id>/read")
@jwt_required()
@active_user_required
def read_notification(notif_id):
    user_id = get_jwt_identity()
    result, code = mark_read(notif_id, user_id)
    return jsonify(result), code


@monitoring_bp.patch("/notifications/read-all")
@jwt_required()
@active_user_required
def read_all_notifications():
    user_id = get_jwt_identity()
    result, code = mark_all_read(user_id)
    return jsonify(result), code
