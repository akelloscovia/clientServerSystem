"""
Response routes — /api/responses
"""
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from marshmallow import ValidationError
from ..extensions import db
from ..models.user import User
from ..models.submission import Submission
from ..models.response import Response
from ..models.assignment import AuditLog
from ..schemas.response_schema import ResponseCreateSchema
from ..services.notification_service import notify_user
from ..utils.permissions import staff_required

responses_bp = Blueprint("responses", __name__)


def _current_user() -> User:
    return User.query.get(get_jwt_identity())


@responses_bp.post("/")
@jwt_required()
@staff_required
def add_response():
    data = request.get_json(silent=True) or {}
    try:
        clean = ResponseCreateSchema().load(data)
    except ValidationError as e:
        return jsonify({"errors": e.messages}), 422

    actor = _current_user()
    sub = Submission.query.get_or_404(clean["submission_id"])

    resp = Response(
        submission_id=clean["submission_id"],
        responder_id=actor.id,
        message=clean["message"],
    )
    db.session.add(resp)

    # Update status to under_review if still pending
    if sub.status == "pending":
        sub.status = "under_review"

    # Audit log
    log = AuditLog(
        user_id=actor.id,
        action="ADD_RESPONSE",
        entity_type="submission",
        entity_id=sub.id,
        details=f"Response added to submission {sub.id}",
        ip_address=request.remote_addr,
    )
    db.session.add(log)

    # Notify submitter
    notify_user(
        sub.user_id, sub.id,
        f"A response has been added to your submission: '{sub.title}'"
    )
    db.session.commit()
    return jsonify({"message": "Response added.", "response": resp.to_dict()}), 201


@responses_bp.get("/<int:submission_id>")
@jwt_required()
def get_responses(submission_id):
    actor = _current_user()
    sub = Submission.query.get_or_404(submission_id)

    # Users can only see their own submission responses
    if actor.role == "user" and sub.user_id != actor.id:
        return jsonify({"error": "Access denied."}), 403

    responses = (Response.query
                 .filter_by(submission_id=submission_id)
                 .order_by(Response.created_at.asc())
                 .all())
    return jsonify({"responses": [r.to_dict() for r in responses]}), 200
