"""
Submission routes — /api/submissions
"""
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from marshmallow import ValidationError
from ..models.user import User
from ..schemas.submission_schema import (
    SubmissionCreateSchema, SubmissionUpdateSchema, AssignmentSchema
)
from ..services.submission_service import (
    create_submission, get_submissions, get_submission,
    update_status, delete_submission, assign_submission
)
from ..utils.permissions import admin_required, staff_required, active_user_required

submissions_bp = Blueprint("submissions", __name__)


def _current_user() -> User:
    return User.query.get(get_jwt_identity())


@submissions_bp.post("/")
@jwt_required()
@active_user_required
def create():
    data = request.get_json(silent=True) or {}
    try:
        clean = SubmissionCreateSchema().load(data)
    except ValidationError as e:
        return jsonify({"errors": e.messages}), 422
    result, status = create_submission(_current_user().id, clean)
    return jsonify(result), status


@submissions_bp.get("/")
@jwt_required()
@active_user_required
def list_submissions():
    user    = _current_user()
    page    = request.args.get("page", 1, type=int)
    per_page = request.args.get("per_page", 20, type=int)
    status  = request.args.get("status")
    category = request.args.get("category")
    result, code = get_submissions(user, page, per_page, status, category)
    return jsonify(result), code


@submissions_bp.get("/<int:sub_id>")
@jwt_required()
@active_user_required
def get_one(sub_id):
    result, code = get_submission(sub_id, _current_user())
    return jsonify(result), code


@submissions_bp.patch("/<int:sub_id>/status")
@jwt_required()
@staff_required
def change_status(sub_id):
    data = request.get_json(silent=True) or {}
    try:
        clean = SubmissionUpdateSchema().load(data)
    except ValidationError as e:
        return jsonify({"errors": e.messages}), 422
    result, code = update_status(sub_id, clean["status"], _current_user())
    return jsonify(result), code


@submissions_bp.delete("/<int:sub_id>")
@jwt_required()
@admin_required
def delete(sub_id):
    result, code = delete_submission(sub_id, _current_user())
    return jsonify(result), code


@submissions_bp.post("/assign")
@jwt_required()
@admin_required
def assign():
    data = request.get_json(silent=True) or {}
    try:
        clean = AssignmentSchema().load(data)
    except ValidationError as e:
        return jsonify({"errors": e.messages}), 422
    result, code = assign_submission(clean, _current_user())
    return jsonify(result), code


@submissions_bp.get("/assignments")
@jwt_required()
@staff_required
def list_assignments():
    from ..models.assignment import Assignment
    user = _current_user()
    if user.role == "secretary":
        items = Assignment.query.filter_by(assigned_to=user.id).all()
    else:
        items = Assignment.query.all()
    return jsonify({"assignments": [a.to_dict() for a in items]}), 200
