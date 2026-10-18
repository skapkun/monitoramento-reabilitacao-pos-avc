import base64
from datetime import datetime, timezone
from uuid import uuid4

import pytest

from app.services.video_storage_service import (
    VideoAccessDeniedError,
    VideoNotFoundError,
    VideoStorageService,
)


def service(tmp_path) -> VideoStorageService:
    key = base64.urlsafe_b64encode(bytes(range(32))).decode("ascii")
    return VideoStorageService(
        storage_dir=tmp_path / "videos",
        database_path=tmp_path / "metadata.sqlite3",
        key_path=tmp_path / "video.key",
        encryption_key=key,
        retention_days=30,
    )


def test_encrypts_and_authorizes_patient_and_therapist(tmp_path) -> None:
    storage = service(tmp_path)
    session_id = uuid4()
    content = b"private-video-content"
    stored = storage.store(
        session_id=session_id,
        patient_id="patient-a",
        therapist_id="therapist-a",
        content_type="video/mp4",
        original_filename="session.mp4",
        consent_at=datetime.now(timezone.utc),
        content=content,
    )

    encrypted_files = list((tmp_path / "videos").glob("*.enc"))
    assert len(encrypted_files) == 1
    assert content not in encrypted_files[0].read_bytes()
    database_content = (tmp_path / "metadata.sqlite3").read_bytes()
    assert str(session_id).encode() not in database_content
    assert b"patient-a" not in database_content
    assert b"therapist-a" not in database_content
    assert storage.retrieve(session_id, "patient-a")[1] == content
    assert storage.retrieve(session_id, "therapist-a")[1] == content
    assert stored.expires_at > stored.created_at

    with pytest.raises(VideoAccessDeniedError):
        storage.retrieve(session_id, "other-user")


def test_only_patient_can_delete_video(tmp_path) -> None:
    storage = service(tmp_path)
    session_id = uuid4()
    storage.store(
        session_id=session_id,
        patient_id="patient-a",
        therapist_id="therapist-a",
        content_type="video/mp4",
        original_filename="session.mp4",
        consent_at=datetime.now(timezone.utc),
        content=b"video",
    )

    with pytest.raises(VideoAccessDeniedError):
        storage.delete(session_id, "therapist-a")

    storage.delete(session_id, "patient-a")
    with pytest.raises(VideoNotFoundError):
        storage.retrieve(session_id, "patient-a")
