"""
Auth routes — /api/auth
"""
import secrets

from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity, create_access_token
from marshmallow import ValidationError
from ..extensions import db, bcrypt
from ..schemas.auth_schema import RegisterSchema, LoginSchema
from ..services.auth_service import register_user, login_user, _make_tokens
from ..models.user import User
from ..utils.permissions import active_user_required

auth_bp = Blueprint("auth", __name__)


@auth_bp.post("/register")
def register():
    data = request.get_json(silent=True) or {}
    try:
        clean = RegisterSchema().load(data)
    except ValidationError as e:
        return jsonify({"errors": e.messages}), 422

    result, status = register_user(
        name=clean["name"],
        email=clean["email"],
        password=clean["password"],
    )
    return jsonify(result), status


@auth_bp.post("/login")
def login():
    data = request.get_json(silent=True) or {}
    try:
        clean = LoginSchema().load(data)
    except ValidationError as e:
        return jsonify({"errors": e.messages}), 422

    result, status = login_user(clean["email"], clean["password"])
    return jsonify(result), status


@auth_bp.post("/refresh")
@jwt_required(refresh=True)
def refresh():
    user_id = int(get_jwt_identity())
    user = User.query.get(user_id)
    if not user:
        return jsonify({"error": "User not found."}), 404
    if not user.is_active:
        return jsonify({"error": "Account is disabled."}), 403
    token = create_access_token(identity=user_id,
                                additional_claims={"role": user.role})
    return jsonify({"access_token": token}), 200


@auth_bp.get("/me")
@jwt_required()
@active_user_required
def me():
    user_id = get_jwt_identity()
    user = User.query.get(user_id)
    if not user:
        return jsonify({"error": "User not found."}), 404
    return jsonify({"user": user.to_dict()}), 200


@auth_bp.post("/user-portal")
def user_portal_access():
    """
    Client-side entry point: identify by email only, no password.
    Used by the web User Portal and the Flutter client's "Client" role —
    login stays password-protected for staff (admin/secretary) only.
    Auto-creates the account on first use.
    """
    data = request.get_json(silent=True) or {}
    email = data.get("email", "").strip().lower()
    name = data.get("name", "").strip()

    if not email:
        return jsonify({"error": "Email is required"}), 400

    user = User.query.filter_by(email=email).first()

    if not user:
        pw_hash = bcrypt.generate_password_hash(secrets.token_urlsafe(24)).decode("utf-8")
        user = User(name=name or email.split("@")[0], email=email, password_hash=pw_hash)
        db.session.add(user)
        db.session.commit()

    if not user.is_active:
        return jsonify({"error": "Account is disabled"}), 403

    tokens = _make_tokens(user)

    return jsonify({
        # Back-compat fields for the web User Portal
        "token": tokens["access_token"],
        "email": user.email,
        "user_id": user.id,
        # Full session fields for the Flutter client
        "user": user.to_dict(),
        **tokens,
    }), 200

