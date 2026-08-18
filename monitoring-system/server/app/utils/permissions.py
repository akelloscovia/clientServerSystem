"""
Permission decorators for role-based access control.
"""
from functools import wraps
from flask import jsonify
from flask_jwt_extended import get_jwt_identity, verify_jwt_in_request
from ..models.user import User


def _get_current_user() -> User | None:
    user_id = get_jwt_identity()
    return User.query.get(user_id)


def roles_required(*roles):
    """Decorator: allow only users with one of the given roles."""
    def decorator(fn):
        @wraps(fn)
        def wrapper(*args, **kwargs):
            verify_jwt_in_request()
            user = _get_current_user()
            if not user or user.role not in roles:
                return jsonify({"error": "Insufficient permissions."}), 403
            if not user.is_active:
                return jsonify({"error": "Account is disabled."}), 403
            return fn(*args, **kwargs)
        return wrapper
    return decorator


def admin_required(fn):
    """Shortcut: admin only."""
    return roles_required("admin")(fn)


def staff_required(fn):
    """Shortcut: admin or secretary."""
    return roles_required("admin", "secretary")(fn)


def active_user_required(fn):
    """Shortcut: any active authenticated user."""
    return roles_required("user", "admin", "secretary")(fn)
