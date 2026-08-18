"""
Marshmallow schemas for Response endpoints.
"""
from marshmallow import Schema, fields, validate


class ResponseCreateSchema(Schema):
    submission_id = fields.Int(required=True)
    message       = fields.Str(required=True, validate=validate.Length(min=1, max=5000))
