"""
Program service — CRUD for the ministry's daily schedule.
"""
from ..extensions import db
from ..models.program import Program


def list_programs(day: str = None, active_only: bool = True) -> tuple[dict, int]:
    query = Program.query
    if active_only:
        query = query.filter_by(is_active=True)
    if day:
        query = query.filter(Program.day.in_([day, "daily"]))
    programs = query.order_by(Program.start_time.asc()).all()
    return {"programs": [p.to_dict() for p in programs]}, 200


def create_program(data: dict) -> tuple[dict, int]:
    program = Program(**data)
    db.session.add(program)
    db.session.commit()
    return {"message": "Program created.", "program": program.to_dict()}, 201


def update_program(program_id: int, data: dict) -> tuple[dict, int]:
    program = Program.query.get_or_404(program_id)
    for key, value in data.items():
        setattr(program, key, value)
    db.session.commit()
    return {"message": "Program updated.", "program": program.to_dict()}, 200


def delete_program(program_id: int) -> tuple[dict, int]:
    program = Program.query.get_or_404(program_id)
    db.session.delete(program)
    db.session.commit()
    return {"message": "Program deleted."}, 200
