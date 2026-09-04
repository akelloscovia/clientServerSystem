"""
Seed script — creates initial admin user and sample data.
Run: python seed.py
"""
from datetime import time
from app import create_app
from app.extensions import db, bcrypt
from app.models.user import User
from app.models.submission import Submission
from app.models.status_history import SubmissionStatusHistory
from app.models.channel import Channel
from app.models.program import Program

app = create_app()

with app.app_context():
    db.create_all()

    # Create admin
    if not User.query.filter_by(email="admin@system.com").first():
        admin = User(
            name="System Admin",
            email="admin@system.com",
            password_hash=bcrypt.generate_password_hash("Admin@123").decode("utf-8"),
            role="admin",
        )
        db.session.add(admin)
        print("✓ Admin created: admin@system.com / Admin@123")

    # Create secretary
    if not User.query.filter_by(email="secretary@system.com").first():
        secretary = User(
            name="Jane Secretary",
            email="secretary@system.com",
            password_hash=bcrypt.generate_password_hash("Secretary@123").decode("utf-8"),
            role="secretary",
        )
        db.session.add(secretary)
        print("✓ Secretary created: secretary@system.com / Secretary@123")

    # Create sample user
    if not User.query.filter_by(email="user@example.com").first():
        user = User(
            name="John User",
            email="user@example.com",
            password_hash=bcrypt.generate_password_hash("User@1234").decode("utf-8"),
            role="user",
        )
        db.session.add(user)
        print("✓ Sample user created: user@example.com / User@1234")

    db.session.commit()

    for submission in Submission.query.all():
        if not submission.status_history:
            db.session.add(SubmissionStatusHistory(
                submission_id=submission.id,
                changed_by=submission.user_id,
                from_status=None,
                to_status=submission.status,
            ))
    db.session.commit()

    # Real Uganda broadcaster channels — their own official live pages/players.
    # Add/edit/reorder any of these from the Channels page in the dashboard.
    BROADCAST_CHANNELS = [
        ("NTV Uganda", "https://ntv.co.ug/live-tv", "other", 1),
        ("NBS TV",     "https://www.nbs.ug/live", "other", 2),
        ("Spark TV",   "https://ntv.co.ug/spark-live-tv-2", "other", 3),
        ("UBC TV",     "https://www.youtube.com/channel/UCehjvG_d36rOJj81HBcWV0A/live", "youtube", 4),
        ("Bukedde TV", "https://www.newvision.co.ug/tv/4", "other", 5),
        ("TV West",    "https://www.bukedde.co.ug/tv/6", "other", 6),
    ]
    for name, stream_url, stream_type, sort_order in BROADCAST_CHANNELS:
        if not Channel.query.filter_by(name=name).first():
            db.session.add(Channel(
                name=name, stream_url=stream_url,
                stream_type=stream_type, sort_order=sort_order,
            ))
            print(f"✓ Channel added: {name}")

    # Drop the old placeholder stream now that real channels are seeded.
    placeholder = Channel.query.filter_by(name="Sample Test Stream").first()
    if placeholder:
        db.session.delete(placeholder)
        print("✓ Removed placeholder Sample Test Stream")

    # Sample daily programs — edit/replace from the Programs page in the dashboard.
    if not Program.query.first():
        db.session.add_all([
            Program(title="Morning Briefing", day="daily",
                    start_time=time(8, 0), end_time=time(8, 30),
                    location="Main Hall",
                    description="Daily briefing for staff and visitors."),
            Program(title="Public Service Hours", day="daily",
                    start_time=time(9, 0), end_time=time(16, 0),
                    location="Reception",
                    description="Front desk open for visitor inquiries."),
            Program(title="Community Outreach", day="friday",
                    start_time=time(14, 0), end_time=time(16, 0),
                    location="Seminar Room",
                    description="Weekly outreach session."),
        ])
        print("✓ Sample daily programs added (edit these from the dashboard)")

    db.session.commit()
    print("\n✅ Database seeded successfully!")
