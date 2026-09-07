"""
Configuration classes for different environments.
"""
import os
from datetime import timedelta
from dotenv import load_dotenv

load_dotenv()

# Insecure fallback secrets — allowed in dev/testing, rejected in production
# by validate_production_config().
_DEV_SECRET_KEY = "dev-secret-key"
_DEV_JWT_SECRET_KEY = "jwt-dev-secret"


def _env_int(name: str, default: int) -> int:
    try:
        return int(os.getenv(name, default))
    except (TypeError, ValueError):
        return default


def _env_bool(name: str, default: bool = False) -> bool:
    return os.getenv(name, str(default)).strip().lower() in ("1", "true", "yes", "on")


class BaseConfig:
    SECRET_KEY = os.getenv("SECRET_KEY", _DEV_SECRET_KEY)
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    # Recycle idle connections and check them before use so a MariaDB/XAMPP
    # restart doesn't leave the pool full of dead "MySQL server has gone away"
    # connections.
    SQLALCHEMY_ENGINE_OPTIONS = {"pool_pre_ping": True, "pool_recycle": 280}
    JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY", _DEV_JWT_SECRET_KEY)
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(
        seconds=_env_int("JWT_ACCESS_TOKEN_EXPIRES", 3600)
    )
    JWT_REFRESH_TOKEN_EXPIRES = timedelta(
        seconds=_env_int("JWT_REFRESH_TOKEN_EXPIRES", 604800)  # 7 days
    )
    CORS_ORIGINS = os.getenv("CORS_ORIGINS", "http://localhost:5173")

    # --- Authentication hardening -------------------------------------------
    # Account lockout: after LOGIN_MAX_ATTEMPTS consecutive failed logins the
    # account is locked for LOGIN_LOCKOUT_MINUTES.
    LOGIN_MAX_ATTEMPTS = _env_int("LOGIN_MAX_ATTEMPTS", 3)
    LOGIN_LOCKOUT_MINUTES = _env_int("LOGIN_LOCKOUT_MINUTES", 15)

    # Password policy (enforced on registration / admin-created accounts).
    PASSWORD_MIN_LENGTH = _env_int("PASSWORD_MIN_LENGTH", 10)
    PASSWORD_MAX_LENGTH = 72  # bcrypt truncates beyond 72 bytes

    # Email validation. Deliverability checks need DNS, so they are off by
    # default (dev / offline) and opt-in for production.
    EMAIL_CHECK_DELIVERABILITY = _env_bool("EMAIL_CHECK_DELIVERABILITY", False)

    # Rate limiting (Flask-Limiter). "memory://" is per-process; point at Redis
    # (e.g. redis://localhost:6379) when running multiple workers.
    RATELIMIT_STORAGE_URI = os.getenv("RATELIMIT_STORAGE_URI", "memory://")
    RATELIMIT_DEFAULT = os.getenv("RATELIMIT_DEFAULT", "200 per hour")

    # Trust X-Forwarded-* headers (only enable behind a reverse proxy you
    # control, otherwise clients can spoof their IP and defeat rate limiting).
    TRUST_PROXY = _env_bool("TRUST_PROXY", False)


class DevelopmentConfig(BaseConfig):
    DEBUG = True
    CORS_ORIGINS = os.getenv("CORS_ORIGINS", "*")
    SQLALCHEMY_DATABASE_URI = os.getenv(
        "DATABASE_URL", "sqlite:///monitoring_dev.db"
    )


class ProductionConfig(BaseConfig):
    DEBUG = False
    SQLALCHEMY_DATABASE_URI = os.getenv("DATABASE_URL")


class TestingConfig(BaseConfig):
    TESTING = True
    SQLALCHEMY_DATABASE_URI = "sqlite:///:memory:"
    RATELIMIT_ENABLED = False


config_map = {
    "development": DevelopmentConfig,
    "production":  ProductionConfig,
    "testing":     TestingConfig,
    "default":     DevelopmentConfig,
}


def validate_production_config(cfg: type[BaseConfig]) -> None:
    """Fail fast if production is running with insecure defaults."""
    problems = []
    if not os.getenv("DATABASE_URL"):
        problems.append("DATABASE_URL is not set")
    if cfg.SECRET_KEY in (None, "", _DEV_SECRET_KEY) or len(cfg.SECRET_KEY) < 32:
        problems.append("SECRET_KEY is missing, a dev default, or shorter than 32 chars")
    if cfg.JWT_SECRET_KEY in (None, "", _DEV_JWT_SECRET_KEY) or len(cfg.JWT_SECRET_KEY) < 32:
        problems.append("JWT_SECRET_KEY is missing, a dev default, or shorter than 32 chars")
    if problems:
        raise RuntimeError(
            "Refusing to start in production with insecure configuration:\n  - "
            + "\n  - ".join(problems)
            + "\nSet these in the environment (see server/.env.example)."
        )
