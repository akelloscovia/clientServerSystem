"""
User management routes — /api/users
Admin-only endpoints for managing user accounts and roles.
"""
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from marshmallow import ValidationError, EXCLUDE
from ..extensions import db, bcrypt
from ..models.user import User
from ..schemas.auth_schema import RegisterSchema
from ..services.auth_service import create_staff_user
from ..utils.permissions import admin_required
from ..models.assignment import AuditLog

users_bp = Blueprint("users", __name__)


@users_bp.post("/")
@jwt_required()
@admin_required
def create_user():
    """Admin creates an account with an explicit role (staff or client)."""
    data = request.get_json(silent=True) or {}
    try:
        clean = RegisterSchema(unknown=EXCLUDE).load(data)
    except ValidationError as e:
        return jsonify({"errors": e.messages}), 422
    role = (data.get("role") or "secretary").strip()
    result, code = create_staff_user(
        clean["name"], clean["email"], clean["password"], role,
        int(get_jwt_identity()),
    )
    return jsonify(result), code


@users_bp.get("/")
@jwt_required()
@admin_required
def list_users():
    role   = request.args.get("role")
    query  = User.query
    if role:
        query = query.filter_by(role=role)
    users = query.order_by(User.created_at.desc()).all()
    return jsonify({"users": [u.to_dict() for u in users]}), 200


@users_bp.get("/<int:user_id>")
@jwt_required()
@admin_required
def get_user(user_id):
    user = User.query.get_or_404(user_id)
    return jsonify({"user": user.to_dict()}), 200


@users_bp.patch("/<int:user_id>/role")
@jwt_required()
@admin_required
def update_role(user_id):
    data = request.get_json(silent=True) or {}
    new_role = data.get("role")
    if new_role not in ("user", "admin", "secretary"):
        return jsonify({"error": "Invalid role. Must be user, admin, or secretary."}), 400
    user = User.query.get_or_404(user_id)
    old_role = user.role
    user.role = new_role
    db.session.add(AuditLog(user_id=int(get_jwt_identity()), action="UPDATE_USER_ROLE", entity_type="user",
                            entity_id=user.id, details=f"{old_role} -> {new_role}"))
    db.session.commit()
    return jsonify({"message": f"Role updated to '{new_role}'.", "user": user.to_dict()}), 200


@users_bp.patch("/<int:user_id>/toggle-active")
@jwt_required()
@admin_required
def toggle_active(user_id):
    user = User.query.get_or_404(user_id)
    if user.id == int(get_jwt_identity()):
        return jsonify({"error": "You cannot deactivate your own account."}), 409
    user.is_active = not user.is_active
    db.session.add(AuditLog(user_id=int(get_jwt_identity()), action="TOGGLE_USER_ACTIVE", entity_type="user",
                            entity_id=user.id, details=f"is_active={user.is_active}"))
    db.session.commit()
    state = "activated" if user.is_active else "deactivated"
    return jsonify({"message": f"User {state}.", "user": user.to_dict()}), 200


@users_bp.get("/secretaries")
@jwt_required()
@admin_required
def list_secretaries():
    secretaries = User.query.filter_by(role="secretary", is_active=True).all()
    return jsonify({"secretaries": [u.to_dict() for u in secretaries]}), 200
