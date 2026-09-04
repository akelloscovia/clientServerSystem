"""
Authentication service — register, login, token management.
"""
from flask import current_app
from flask_jwt_extended import create_access_token, create_refresh_token
from ..extensions import db, bcrypt
from ..models.user import User
from ..models.assignment import AuditLog
from flask import request


def _audit(user_id, action, entity_type=None, entity_id=None, details=None):
    log = AuditLog(
        user_id=user_id,
        action=action,
        entity_type=entity_type,
        entity_id=entity_id,
        details=details,
        ip_address=request.remote_addr,
    )
    db.session.add(log)


def register_user(name: str, email: str, password: str) -> tuple[dict, int]:
    """Register a new user. Returns (response_dict, http_status)."""
    if User.query.filter_by(email=email.lower()).first():
        return {"error": "Email already registered."}, 409

    pw_hash = bcrypt.generate_password_hash(password).decode("utf-8")
    user = User(name=name, email=email.lower(), password_hash=pw_hash)
    db.session.add(user)
    db.session.flush()
    _audit(user.id, "REGISTER", "user", user.id, f"New user: {email}")
    db.session.commit()

    tokens = _make_tokens(user)
    return {"message": "Registration successful.", "user": user.to_dict(), **tokens}, 201


def create_staff_user(name: str, email: str, password: str, role: str,
                      actor_id: int) -> tuple[dict, int]:
    """Admin-only: create an account with an explicit role (no tokens issued)."""
    if role not in ("user", "secretary", "admin"):
        return {"error": "Invalid role. Must be user, secretary, or admin."}, 400
    if User.query.filter_by(email=email.lower()).first():
        return {"error": "Email already registered."}, 409

    pw_hash = bcrypt.generate_password_hash(password).decode("utf-8")
    user = User(name=name, email=email.lower(), password_hash=pw_hash, role=role)
    db.session.add(user)
    db.session.flush()
    _audit(actor_id, "CREATE_STAFF", "user", user.id, f"{email} as {role}")
    db.session.commit()
    return {"message": f"Account created for {email}.", "user": user.to_dict()}, 201


def login_user(email: str, password: str) -> tuple[dict, int]:
    """Authenticate user. Returns (response_dict, http_status)."""
    user = User.query.filter_by(email=email.lower()).first()
    if not user or not bcrypt.check_password_hash(user.password_hash, password):
        return {"error": "Invalid email or password."}, 401
    if not user.is_active:
        return {"error": "Account is disabled. Contact administrator."}, 403

    _audit(user.id, "LOGIN", "user", user.id)
    db.session.commit()

    tokens = _make_tokens(user)
    return {"message": "Login successful.", "user": user.to_dict(), **tokens}, 200


def _make_tokens(user: User) -> dict:
    return {
        "access_token":  create_access_token(identity=str(user.id),
                                             additional_claims={"role": user.role}),
        "refresh_token": create_refresh_token(identity=str(user.id)),
    }
