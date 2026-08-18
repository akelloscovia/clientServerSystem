"""
Flask application factory.
"""
from flask import Flask
from flask_cors import CORS
from .config import config_map
from .extensions import db, migrate, jwt, bcrypt
from .routes.auth import auth_bp
from .routes.submissions import submissions_bp
from .routes.responses import responses_bp
from .routes.monitoring import monitoring_bp
from .routes.users import users_bp
import os


def create_app(config_name: str = None) -> Flask:
    """Create and configure the Flask application."""
    app = Flask(__name__)

    # Load config
    env = config_name or os.getenv("FLASK_ENV", "development")
    app.config.from_object(config_map[env])

    # CORS
    CORS(app, origins=app.config.get("CORS_ORIGINS", "*").split(","),
         supports_credentials=True)

    # Extensions
    db.init_app(app)
    migrate.init_app(app, db)
    jwt.init_app(app)
    bcrypt.init_app(app)

    # Register blueprints
    app.register_blueprint(auth_bp,        url_prefix="/api/auth")
    app.register_blueprint(submissions_bp, url_prefix="/api/submissions")
    app.register_blueprint(responses_bp,   url_prefix="/api/responses")
    app.register_blueprint(monitoring_bp,  url_prefix="/api/monitoring")
    app.register_blueprint(users_bp,       url_prefix="/api/users")

    # Health check
    @app.get("/api/health")
    def health():
        return {"status": "ok", "service": "monitoring-system"}, 200

    # Import models so Flask-Migrate can detect them
    with app.app_context():
        from .models import user, submission, response, assignment, notification  # noqa

    return app
