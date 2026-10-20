import base64
from datetime import datetime, timezone
from uuid import uuid4

from fastapi.testclient import TestClient

from app.main import app
from app.routes import videos as videos_route
from app.security.firebase_auth import AuthenticatedUser, require_authenticated_user
from app.services.video_storage_service import VideoStorageService


client = TestClient(app)


class _AnnotatedVideoStub:
    def render(self, content, exercise_type, analyzed_side=None):
        assert content == b"video-content"
        assert exercise_type.value == "elbow_flexion"
        assert analyzed_side == "right"
        return b"annotated-video"


def test_private_video_flow(tmp_path, monkeypatch) -> None:
    storage = VideoStorageService(
        storage_dir=tmp_path / "videos",
        database_path=tmp_path / "metadata.sqlite3",
        key_path=tmp_path / "video.key",
        encryption_key=base64.urlsafe_b64encode(bytes(range(32))).decode("ascii"),
    )
    monkeypatch.setattr(videos_route, "video_storage_service", storage)
    monkeypatch.setattr(
        videos_route, "annotated_video_service", _AnnotatedVideoStub()
    )
    session_id = uuid4()
    app.dependency_overrides[require_authenticated_user] = lambda: AuthenticatedUser(
        uid="patient-a"
    )
    try:
        uploaded = client.post(
            "/videos",
            data={
                "session_id": str(session_id),
                "therapist_id": "therapist-a",
                "consent_at": datetime.now(timezone.utc).isoformat(),
            },
            files={"video_file": ("movement.mp4", b"video-content", "video/mp4")},
        )
        assert uploaded.status_code == 201
        assert uploaded.json()["data"]["storage_path"] == f"fastapi://videos/{session_id}"

        app.dependency_overrides[require_authenticated_user] = lambda: AuthenticatedUser(
            uid="therapist-a"
        )
        downloaded = client.get(f"/videos/{session_id}")
        assert downloaded.status_code == 200
        assert downloaded.content == b"video-content"
        assert downloaded.headers["cache-control"] == "private, no-store"

        annotated = client.get(
            f"/videos/{session_id}/annotated",
            params={
                "exercise_type": "elbow_flexion",
                "analyzed_side": "right",
            },
        )
        assert annotated.status_code == 200
        assert annotated.content == b"annotated-video"
        assert annotated.headers["content-type"] == "video/mp4"

        app.dependency_overrides[require_authenticated_user] = lambda: AuthenticatedUser(
            uid="other-user"
        )
        assert client.get(f"/videos/{session_id}").status_code == 404

        app.dependency_overrides[require_authenticated_user] = lambda: AuthenticatedUser(
            uid="patient-a"
        )
        assert client.delete(f"/videos/{session_id}").status_code == 204
        assert client.get(f"/videos/{session_id}").status_code == 404
    finally:
        app.dependency_overrides.clear()
