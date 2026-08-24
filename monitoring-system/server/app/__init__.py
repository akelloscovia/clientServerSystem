"""
Flask application factory.
"""
from flask import Flask
from flask import jsonify, request
from flask_jwt_extended import jwt_required, get_jwt_identity
from flask_cors import CORS
from .config import config_map
from .extensions import db, migrate, jwt, bcrypt
from .routes.auth import auth_bp
from .routes.submissions import submissions_bp
from .routes.responses import responses_bp
from .routes.monitoring import monitoring_bp
from .routes.users import users_bp
from .models.user import User
from .services.submission_service import get_submissions
from .utils.permissions import active_user_required
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

    # Keep the documented v1 path available while existing clients migrate.
    app.register_blueprint(auth_bp,        url_prefix="/api/v1/auth", name="auth_v1")
    app.register_blueprint(submissions_bp, url_prefix="/api/v1/submissions", name="submissions_v1")
    app.register_blueprint(responses_bp,   url_prefix="/api/v1/responses", name="responses_v1")
    app.register_blueprint(monitoring_bp,  url_prefix="/api/v1/monitoring", name="monitoring_v1")
    app.register_blueprint(users_bp,       url_prefix="/api/v1/users", name="users_v1")

    # Health check
    @app.get("/api/health")
    @app.get("/api/v1/health")
    def health():
        return {"status": "ok", "service": "monitoring-system"}, 200

    @app.get("/api/")
    @app.get("/api/v1/")
    @jwt_required()
    @active_user_required
    def submissions_compatibility():
        """Compatibility for older clients that omitted /submissions."""
        user = User.query.get(get_jwt_identity())
        result, code = get_submissions(
            user,
            request.args.get("page", 1, type=int),
            request.args.get("per_page", 20, type=int),
            request.args.get("status"),
            request.args.get("category"),
            request.args.get("priority"),
            request.args.get("search"),
            request.args.get("from"),
            request.args.get("to"),
            request.args.get("assigned_to", type=int),
        )
        return jsonify(result), code

    @app.errorhandler(404)
    def not_found(_error):
        return jsonify({"error": "Resource not found."}), 404

    @app.errorhandler(405)
    def method_not_allowed(_error):
        return jsonify({"error": "HTTP method is not allowed for this resource."}), 405

    @app.errorhandler(422)
    def unprocessable(_error):
        return jsonify({"error": "The request could not be processed."}), 422

    # Import models so Flask-Migrate can detect them
    with app.app_context():
        from .models import user, submission, response, assignment, notification, status_history  # noqa
        if env == "development":
            db.create_all()

    @app.errorhandler(500)
    def internal_error(_error):
        db.session.rollback()
        return jsonify({"error": "Internal server error."}), 500

    return app
