"""
Visitor log routes — /api/visitors

The create endpoint is public: visitors scan a QR code shown on the
reception kiosk and fill the form in with no login required. Everything
else (view/assign/reply/delete) is staff-only and kept separate from the
case-submission system.
"""
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from marshmallow import ValidationError
from ..models.user import User
from ..schemas.visitor_schema import (
    VisitorCreateSchema, VisitorStatusSchema, VisitorAssignSchema, VisitorReplySchema
)
from ..services.visitor_service import (
    create_visitor, get_visitors, get_visitor, update_visitor_status,
    assign_visitor, delete_visitor, add_reply
)
from ..utils.permissions import admin_required, staff_required

visitors_bp = Blueprint("visitors", __name__)


def _current_user() -> User:
    return User.query.get(get_jwt_identity())


@visitors_bp.post("/")
def create():
    data = request.get_json(silent=True) or {}
    try:
        clean = VisitorCreateSchema().load(data)
    except ValidationError as e:
        return jsonify({"errors": e.messages}), 422
    result, status = create_visitor(clean)
    return jsonify(result), status


@visitors_bp.get("/")
@jwt_required()
@staff_required
def list_visitors():
    page = request.args.get("page", 1, type=int)
    per_page = request.args.get("per_page", 20, type=int)
    status = request.args.get("status")
    result, code = get_visitors(page, per_page, status)
    return jsonify(result), code


@visitors_bp.get("/<int:visitor_id>")
@jwt_required()
@staff_required
def get_one(visitor_id):
    result, code = get_visitor(visitor_id)
    return jsonify(result), code


@visitors_bp.patch("/<int:visitor_id>/status")
@jwt_required()
@staff_required
def change_status(visitor_id):
    data = request.get_json(silent=True) or {}
    try:
        clean = VisitorStatusSchema().load(data)
    except ValidationError as e:
        return jsonify({"errors": e.messages}), 422
    result, code = update_visitor_status(visitor_id, clean["status"])
    return jsonify(result), code


@visitors_bp.post("/<int:visitor_id>/assign")
@jwt_required()
@admin_required
def assign(visitor_id):
    data = request.get_json(silent=True) or {}
    try:
        clean = VisitorAssignSchema().load(data)
    except ValidationError as e:
        return jsonify({"errors": e.messages}), 422
    result, code = assign_visitor(visitor_id, clean["assigned_to"], _current_user())
    return jsonify(result), code


@visitors_bp.post("/<int:visitor_id>/replies")
@jwt_required()
@staff_required
def reply(visitor_id):
    data = request.get_json(silent=True) or {}
    try:
        clean = VisitorReplySchema().load(data)
    except ValidationError as e:
        return jsonify({"errors": e.messages}), 422
    result, code = add_reply(visitor_id, _current_user().id, clean["message"])
    return jsonify(result), code


@visitors_bp.delete("/<int:visitor_id>")
@jwt_required()
@admin_required
def delete(visitor_id):
    result, code = delete_visitor(visitor_id)
    return jsonify(result), code
