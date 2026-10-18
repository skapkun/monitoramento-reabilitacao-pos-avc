import os
from dataclasses import dataclass


@dataclass(frozen=True)
class Settings:
    app_name: str = "Movere API"
    app_version: str = "0.1.0"
    environment: str = os.getenv("ENVIRONMENT", "development")
    max_upload_bytes: int = int(os.getenv("MAX_UPLOAD_BYTES", str(100 * 1024 * 1024)))
    analysis_mode: str = os.getenv("ANALYSIS_MODE", "mock").strip().lower()
    auth_mode: str = os.getenv("AUTH_MODE", "disabled").strip().lower()
    firebase_project_id: str = os.getenv("FIREBASE_PROJECT_ID", "movere-dc610").strip()
    firebase_check_revoked: bool = os.getenv("FIREBASE_CHECK_REVOKED", "false").strip().lower() == "true"
    analysis_temp_dir: str = os.getenv("ANALYSIS_TEMP_DIR", "")
    video_storage_dir: str = os.getenv("VIDEO_STORAGE_DIR", "data/videos")
    video_database_path: str = os.getenv(
        "VIDEO_DATABASE_PATH", "data/video_metadata.sqlite3"
    )
    video_key_path: str = os.getenv("VIDEO_KEY_PATH", "data/video.key")
    video_encryption_key: str = os.getenv("VIDEO_ENCRYPTION_KEY", "").strip()
    video_retention_days: int = int(os.getenv("VIDEO_RETENTION_DAYS", "30"))
    video_cleanup_interval_seconds: int = int(
        os.getenv("VIDEO_CLEANUP_INTERVAL_SECONDS", "21600")
    )
    allowed_origins: tuple[str, ...] = tuple(
        origin.strip()
        for origin in os.getenv(
            "ALLOWED_ORIGINS",
            "http://localhost:3000,http://localhost:8080",
        ).split(",")
        if origin.strip()
    )


settings = Settings()
