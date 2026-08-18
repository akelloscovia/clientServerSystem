"""
Marshmallow schemas for auth endpoints.
"""
from marshmallow import Schema, fields, validate, validates, ValidationError
import re


class RegisterSchema(Schema):
    name  = fields.Str(required=True, validate=validate.Length(min=2, max=120))
    email = fields.Email(required=True)
    password = fields.Str(required=True, load_only=True,
                          validate=validate.Length(min=8, max=128))

    @validates("password")
    def validate_password(self, value):
        if not re.search(r"[A-Z]", value):
            raise ValidationError("Password must contain at least one uppercase letter.")
        if not re.search(r"[0-9]", value):
            raise ValidationError("Password must contain at least one digit.")


class LoginSchema(Schema):
    email    = fields.Email(required=True)
    password = fields.Str(required=True, load_only=True)


class ChangePasswordSchema(Schema):
    current_password = fields.Str(required=True, load_only=True)
    new_password     = fields.Str(required=True, load_only=True,
                                  validate=validate.Length(min=8, max=128))
