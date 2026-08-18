"""
Marshmallow schemas for Submission endpoints.
"""
from marshmallow import Schema, fields, validate

CATEGORIES = ["complaint", "inquiry", "report", "request", "other"]
PRIORITIES  = ["low", "medium", "high", "urgent"]
STATUSES    = ["pending", "under_review", "assigned", "resolved", "closed"]


class SubmissionCreateSchema(Schema):
    title       = fields.Str(required=True, validate=validate.Length(min=5, max=200))
    description = fields.Str(required=True, validate=validate.Length(min=10))
    category    = fields.Str(load_default="other",
                             validate=validate.OneOf(CATEGORIES))
    priority    = fields.Str(load_default="medium",
                             validate=validate.OneOf(PRIORITIES))


class SubmissionUpdateSchema(Schema):
    status = fields.Str(required=True, validate=validate.OneOf(STATUSES))


class AssignmentSchema(Schema):
    submission_id = fields.Int(required=True)
    assigned_to   = fields.Int(required=True)
    notes         = fields.Str(load_default="")
