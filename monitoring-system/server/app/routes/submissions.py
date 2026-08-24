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
    priority = request.args.get("priority")
    search = request.args.get("search")
    date_from = request.args.get("from")
    date_to = request.args.get("to")
    assigned_to = request.args.get("assigned_to", type=int)
    result, code = get_submissions(user, page, per_page, status, category, priority,
                                   search, date_from, date_to, assigned_to)
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


@submissions_bp.get("/<int:sub_id>/status-history")
@jwt_required()
@active_user_required
def status_history(sub_id):
    from ..services.submission_service import get_status_history
    result, code = get_status_history(sub_id, _current_user())
    return jsonify(result), code


@submissions_bp.get("/user")
@jwt_required()
def user_submissions():
    """
    Get submissions for a user via token (web portal access).
    Can be accessed with a user token from the portal.
    """
    user = _current_user()
    page = request.args.get("page", 1, type=int)
    per_page = request.args.get("per_page", 20, type=int)
    
    if not user.is_active:
        return jsonify({"error": "Account is inactive"}), 403
    
    result, code = get_submissions(
        user, page, per_page, 
        status=None, category=None, priority=None,
        search=None, date_from=None, date_to=None, assigned_to=None
    )
    
    if code == 200:
        return jsonify({
            "user": {"id": user.id, "email": user.email, "name": user.name},
            "submissions": result.get("submissions", []),
            "total": result.get("total", 0),
            "pages": result.get("pages", 0),
            "page": page
        }), 200
    
    return jsonify(result), code

