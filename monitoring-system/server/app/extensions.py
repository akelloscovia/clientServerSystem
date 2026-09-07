"""
Flask extension instances (initialized in create_app).
"""
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from flask_jwt_extended import JWTManager
from flask_bcrypt import Bcrypt
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address

db      = SQLAlchemy()
migrate = Migrate()
jwt     = JWTManager()
bcrypt  = Bcrypt()

# Rate limiter. Storage URI and default limit come from config; keying is by
# client IP (see TRUST_PROXY / ProxyFix in create_app for proxy handling).
limiter = Limiter(key_func=get_remote_address)
