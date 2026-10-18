from uuid import uuid4

import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.analysis.models import AnalysisOutcome, ElbowFlexionResult, Repetition
from app.routes import analysis as analysis_route
from app.security.firebase_auth import AuthenticatedUser, require_authenticated_user
from app.services.analysis_service import AnalysisService


client = TestClient(app)


def test_accepts_video_for_mock_analysis() -> None:
    session_id = uuid4()
    response = client.post(
        "/analysis",
        data={"exercise_type": "elbow_flexion", "session_id": str(session_id)},
        files={"video_file": ("movement.mp4", b"fake-video-content", "video/mp4")},
    )

    assert response.status_code == 202
    payload = response.json()
    assert payload["data"]["session_id"] == str(session_id)
    assert payload["data"]["status"] == "processing"
    assert payload["data"]["simulated"] is True

    result_response = client.get(f"/analysis/{payload['data']['analysis_id']}")
    assert result_response.status_code == 200
    result = result_response.json()["data"]
    assert result["status"] == "completed"
    assert result["simulated"] is True
    assert result["metrics"]["source"] == "mock"


@pytest.mark.parametrize("exercise_type", ["squat", "pinch"])
def test_accepts_other_article_exercises(exercise_type: str) -> None:
    response = client.post(
        "/analysis",
        data={"exercise_type": exercise_type, "session_id": str(uuid4())},
        files={"video_file": ("movement.mp4", b"fake-video-content", "video/mp4")},
    )

    assert response.status_code == 202
    payload = response.json()["data"]
    assert payload["exercise_type"] == exercise_type


def test_rejects_invalid_video_type() -> None:
    response = client.post(
        "/analysis",
        data={"exercise_type": "elbow_flexion", "session_id": str(uuid4())},
        files={"video_file": ("notes.txt", b"not-a-video", "text/plain")},
    )

    assert response.status_code == 400
    assert response.json()["detail"] == "Envie um vídeo MP4, MOV ou WebM válido."


def test_rejects_empty_video() -> None:
    response = client.post(
        "/analysis",
        data={"exercise_type": "elbow_flexion", "session_id": str(uuid4())},
        files={"video_file": ("empty.mp4", b"", "video/mp4")},
    )

    assert response.status_code == 400
    assert response.json()["detail"] == "O arquivo de vídeo está vazio."


def test_rejects_incomplete_or_unsafe_calibration() -> None:
    incomplete = client.post(
        "/analysis",
        data={
            "exercise_type": "elbow_flexion",
            "session_id": str(uuid4()),
            "detection_start_threshold": "150",
        },
        files={"video_file": ("movement.mp4", b"video", "video/mp4")},
    )
    assert incomplete.status_code == 422
    assert "dois limiares" in incomplete.json()["detail"]

    unsafe = client.post(
        "/analysis",
        data={
            "exercise_type": "pinch",
            "session_id": str(uuid4()),
            "detection_start_threshold": "0.08",
            "detection_change_threshold": "0.07",
        },
        files={"video_file": ("movement.mp4", b"video", "video/mp4")},
    )
    assert unsafe.status_code == 422
    assert "pelo menos 0,02" in unsafe.json()["detail"]


def test_returns_404_for_unknown_analysis() -> None:
    response = client.get(f"/analysis/{uuid4()}")

    assert response.status_code == 404


def test_real_route_processes_elbow_and_returns_metrics(monkeypatch) -> None:
    class Pipeline:
        def analyze_video(self, _path):
            return ElbowFlexionResult(
                status=AnalysisOutcome.SUCCESS,
                message="Movimento processado tecnicamente.",
                side="left",
                confidence=0.9,
                valid_frames=80,
                total_frames=90,
                detection_ratio=0.889,
                repetitions=[
                    Repetition(
                        number=1,
                        start_seconds=0,
                        end_seconds=2,
                        minimum_angle_degrees=65,
                        maximum_angle_degrees=158,
                        amplitude_degrees=93,
                    )
                ],
                average_amplitude_degrees=93,
            )

    service = AnalysisService(mode="real", pipeline=Pipeline())
    monkeypatch.setattr(analysis_route, "analysis_service", service)
    response = client.post(
        "/analysis",
        data={"exercise_type": "elbow_flexion", "session_id": str(uuid4())},
        files={"video_file": ("movement.mp4", b"video-content", "video/mp4")},
    )

    assert response.status_code == 202
    accepted = response.json()["data"]
    assert accepted["simulated"] is False

    result = client.get(f"/analysis/{accepted['analysis_id']}").json()["data"]
    assert result["status"] == "completed"
    assert result["simulated"] is False
    assert result["metrics"]["source"] == "computer_vision"
    assert result["metrics"]["repetitions"] == 1


def test_analysis_result_is_visible_only_to_its_owner() -> None:
    app.dependency_overrides[require_authenticated_user] = lambda: AuthenticatedUser(
        uid="patient-a"
    )
    try:
        response = client.post(
            "/analysis",
            data={"exercise_type": "elbow_flexion", "session_id": str(uuid4())},
            files={"video_file": ("movement.mp4", b"video", "video/mp4")},
        )
        assert response.status_code == 202
        analysis_id = response.json()["data"]["analysis_id"]

        app.dependency_overrides[require_authenticated_user] = lambda: AuthenticatedUser(
            uid="patient-b"
        )
        hidden = client.get(f"/analysis/{analysis_id}")

        assert hidden.status_code == 404
    finally:
        app.dependency_overrides.clear()
