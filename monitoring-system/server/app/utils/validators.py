"""
Input validators used across routes.
"""
import re
from marshmallow import ValidationError

try:  # available at request time; guard so the module imports standalone
    from flask import current_app
except Exception:  # pragma: no cover
    current_app = None

# Fallbacks used when there is no application context (e.g. unit-testing the
# validator directly). Kept in sync with config.BaseConfig.
_DEFAULT_MIN_LENGTH = 10
_MAX_LENGTH = 72  # bcrypt truncates beyond 72 bytes


def _password_min_length() -> int:
    try:
        return int(current_app.config["PASSWORD_MIN_LENGTH"])
    except Exception:
        return _DEFAULT_MIN_LENGTH


def validate_email_format(email: str) -> bool:
    pattern = r"^[\w\.-]+@[\w\.-]+\.\w{2,}$"
    return bool(re.match(pattern, email or ""))


def validate_password_strength(password: str) -> list[str]:
    """Return a list of policy violations; an empty list means the password is OK."""
    errors: list[str] = []
    password = password or ""
    min_len = _password_min_length()

    if len(password) < min_len:
        errors.append(f"Password must be at least {min_len} characters.")
    if len(password) > _MAX_LENGTH:
        errors.append(f"Password must be at most {_MAX_LENGTH} characters.")
    if not re.search(r"[A-Z]", password):
        errors.append("Password must contain at least one uppercase letter.")
    if not re.search(r"[a-z]", password):
        errors.append("Password must contain at least one lowercase letter.")
    if not re.search(r"[0-9]", password):
        errors.append("Password must contain at least one digit.")
    if not re.search(r"[^A-Za-z0-9]", password):
        errors.append("Password must contain at least one symbol.")
    if re.search(r"\s", password):
        errors.append("Password must not contain spaces.")
    return errors


def parse_schema(schema_class, data: dict) -> dict:
    """Parse and validate data using a marshmallow schema.
    Raises a 422-friendly dict on error."""
    schema = schema_class()
    errors = schema.validate(data)
    if errors:
        raise ValidationError(errors)
    return schema.load(data)
