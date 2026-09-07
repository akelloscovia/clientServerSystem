"""
Marshmallow schemas for auth endpoints.
"""
from marshmallow import Schema, fields, validate, validates, post_load, ValidationError

from ..utils.validators import validate_password_strength

try:
    from flask import current_app
except Exception:  # pragma: no cover
    current_app = None

from email_validator import validate_email as _validate_email, EmailNotValidError


class StrictEmail(fields.String):
    """Email field backed by the `email-validator` library.

    Normalises to a lowercased, trimmed address. Deliverability (DNS) checks are
    controlled by the EMAIL_CHECK_DELIVERABILITY config flag (off by default).
    """

    def _deserialize(self, value, attr, data, **kwargs):
        value = super()._deserialize(value, attr, data, **kwargs)
        check_deliverability = False
        try:
            check_deliverability = bool(current_app.config["EMAIL_CHECK_DELIVERABILITY"])
        except Exception:
            pass
        try:
            result = _validate_email(
                (value or "").strip(),
                check_deliverability=check_deliverability,
            )
        except EmailNotValidError as exc:
            raise ValidationError(str(exc)) from exc
        return result.normalized.lower()


def _validate_password_field(value: str) -> None:
    errors = validate_password_strength(value)
    if errors:
        raise ValidationError(errors)


class RegisterSchema(Schema):
    name  = fields.Str(required=True, validate=validate.Length(min=2, max=120))
    email = StrictEmail(required=True)
    password = fields.Str(required=True, load_only=True,
                          validate=validate.Length(min=10, max=72))

    @validates("password")
    def validate_password(self, value):
        _validate_password_field(value)

    @post_load
    def _strip_name(self, data, **kwargs):
        if "name" in data and isinstance(data["name"], str):
            data["name"] = data["name"].strip()
        return data


class LoginSchema(Schema):
    email    = StrictEmail(required=True)
    password = fields.Str(required=True, load_only=True,
                          validate=validate.Length(max=128))


class ChangePasswordSchema(Schema):
    current_password = fields.Str(required=True, load_only=True)
    new_password     = fields.Str(required=True, load_only=True,
                                  validate=validate.Length(min=10, max=72))

    @validates("new_password")
    def validate_new_password(self, value):
        _validate_password_field(value)
