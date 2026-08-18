"""
Input validators used across routes.
"""
import re
from marshmallow import ValidationError


def validate_email_format(email: str) -> bool:
    pattern = r"^[\w\.-]+@[\w\.-]+\.\w{2,}$"
    return bool(re.match(pattern, email))


def validate_password_strength(password: str) -> list[str]:
    """Return list of errors; empty list means valid."""
    errors = []
    if len(password) < 8:
        errors.append("Password must be at least 8 characters.")
    if not re.search(r"[A-Z]", password):
        errors.append("Password must contain at least one uppercase letter.")
    if not re.search(r"[0-9]", password):
        errors.append("Password must contain at least one digit.")
    return errors


def parse_schema(schema_class, data: dict) -> dict:
    """Parse and validate data using a marshmallow schema.
    Raises a 422-friendly dict on error."""
    schema = schema_class()
    errors = schema.validate(data)
    if errors:
        raise ValidationError(errors)
    return schema.load(data)
