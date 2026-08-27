"""
Marshmallow schema for daily program (ministry schedule) endpoints.
"""
from marshmallow import Schema, fields, validate

DAYS = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday", "daily"]


class ProgramSchema(Schema):
    title       = fields.Str(required=True, validate=validate.Length(min=2, max=200))
    description = fields.Str(load_default="", allow_none=True)
    day         = fields.Str(load_default="daily", validate=validate.OneOf(DAYS))
    start_time  = fields.Time(required=True, format="%H:%M")
    end_time    = fields.Time(required=True, format="%H:%M")
    location    = fields.Str(load_default=None, allow_none=True, validate=validate.Length(max=200))
    is_active   = fields.Bool(load_default=True)
