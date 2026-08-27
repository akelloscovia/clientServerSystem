"""
Marshmallow schema for TV channel endpoints.
"""
from marshmallow import Schema, fields, validate

STREAM_TYPES = ["hls", "youtube", "mp4", "other"]


class ChannelSchema(Schema):
    name        = fields.Str(required=True, validate=validate.Length(min=1, max=100))
    stream_url  = fields.Str(required=True, validate=validate.Length(min=5, max=500))
    logo_url    = fields.Str(load_default="", allow_none=True, validate=validate.Length(max=500))
    stream_type = fields.Str(load_default="hls", validate=validate.OneOf(STREAM_TYPES))
    sort_order  = fields.Int(load_default=0)
    is_active   = fields.Bool(load_default=True)
