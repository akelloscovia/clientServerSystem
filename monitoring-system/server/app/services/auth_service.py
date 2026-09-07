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
    """Authenticate user with brute-force lockout. Returns (response_dict, http_status)."""
    max_attempts = current_app.config["LOGIN_MAX_ATTEMPTS"]
    lockout_minutes = current_app.config["LOGIN_LOCKOUT_MINUTES"]

    user = User.query.filter_by(email=email.lower()).first()

    # Account already locked — reject before checking the password so a locked
    # account can't be probed.
    if user and user.is_locked():
        _audit(user.id, "LOGIN_BLOCKED", "user", user.id, "Login attempt while locked")
        db.session.commit()
        return {
            "error": (
                f"Account locked after too many failed attempts. "
                f"Try again in about {user.lockout_minutes_remaining()} minute(s)."
            )
        }, 423

    if not user or not bcrypt.check_password_hash(user.password_hash, password):
        if user:
            user.record_failed_login(max_attempts, lockout_minutes)
            if user.is_locked():
                _audit(user.id, "ACCOUNT_LOCKED", "user", user.id,
                       f"Locked for {lockout_minutes} min after {max_attempts} failed logins")
            else:
                _audit(user.id, "LOGIN_FAILED", "user", user.id,
                       f"Failed attempt {user.failed_login_attempts}/{max_attempts}")
            db.session.commit()
        return {"error": "Invalid email or password."}, 401

    if not user.is_active:
        return {"error": "Account is disabled. Contact administrator."}, 403

    if user.failed_login_attempts or user.locked_until:
        user.reset_lockout()

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
