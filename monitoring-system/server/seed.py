"""
Seed script — creates initial admin user and sample data.
Run: python seed.py
"""
from app import create_app
from app.extensions import db, bcrypt
from app.models.user import User
from app.models.submission import Submission
from app.models.status_history import SubmissionStatusHistory

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
    print("\n✅ Database seeded successfully!")
