"""
Program routes — /api/programs

Listing is public so the reception kiosk can display today's schedule
without logging in. Creating, editing and deleting are admin or secretary.
"""
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required
from marshmallow import ValidationError
from ..schemas.program_schema import ProgramSchema
from ..services.program_service import list_programs, create_program, update_program, delete_program
from ..utils.permissions import staff_required

programs_bp = Blueprint("programs", __name__)


@programs_bp.get("/")
def list_all():
    day = request.args.get("day")
    active_only = request.args.get("all") != "1"
    result, code = list_programs(day, active_only)
    return jsonify(result), code


@programs_bp.post("/")
@jwt_required()
@staff_required
def create():
    data = request.get_json(silent=True) or {}
    try:
        clean = ProgramSchema().load(data)
    except ValidationError as e:
        return jsonify({"errors": e.messages}), 422
    result, status = create_program(clean)
    return jsonify(result), status


@programs_bp.put("/<int:program_id>")
@jwt_required()
@staff_required
def update(program_id):
    data = request.get_json(silent=True) or {}
    try:
        clean = ProgramSchema().load(data)
    except ValidationError as e:
        return jsonify({"errors": e.messages}), 422
    result, code = update_program(program_id, clean)
    return jsonify(result), code


@programs_bp.delete("/<int:program_id>")
@jwt_required()
@staff_required
def delete(program_id):
    result, code = delete_program(program_id)
    return jsonify(result), code
