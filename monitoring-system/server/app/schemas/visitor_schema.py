"""
Marshmallow schemas for the visitor log endpoints.
"""
from marshmallow import Schema, fields, validate

STATUSES = ["pending", "assigned", "attended", "closed"]


class VisitorCreateSchema(Schema):
    name             = fields.Str(required=True, validate=validate.Length(min=2, max=150))
    company          = fields.Str(load_default="", allow_none=True, validate=validate.Length(max=150))
    visit_date       = fields.Date(required=True)
    time_in          = fields.Time(required=True, format="%H:%M")
    reason_for_visit = fields.Str(required=True, validate=validate.Length(min=3, max=300))
    description      = fields.Str(load_default="", allow_none=True)


class VisitorStatusSchema(Schema):
    status = fields.Str(required=True, validate=validate.OneOf(STATUSES))


class VisitorAssignSchema(Schema):
    assigned_to = fields.Int(required=True)


class VisitorReplySchema(Schema):
    message = fields.Str(required=True, validate=validate.Length(min=1))
