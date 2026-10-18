import base64
from datetime import datetime, timezone

import cv2
import numpy as np
from fastapi.testclient import TestClient

from app.main import create_app
from app.security.firebase_auth import AuthenticatedUser, require_authenticated_user


def authenticated_user() -> AuthenticatedUser:
    return AuthenticatedUser(uid="therapist-1", email="fisio@example.com")


def test_generates_longitudinal_pdf() -> None:
    app = create_app()
    app.dependency_overrides[require_authenticated_user] = authenticated_user
    client = TestClient(app)
    ok, encoded = cv2.imencode(
        ".jpg", np.full((120, 160, 3), 180, dtype=np.uint8)
    )
    assert ok

    response = client.post(
        "/reports/longitudinal.pdf",
        json={
            "patient_name": "Paciente Teste",
            "patient_id": "patient-1",
            "sessions": [
                {
                    "date": datetime(2026, 10, 1, tzinfo=timezone.utc).isoformat(),
                    "exercise": "Flexão de cotovelo",
                    "status": "completed",
                    "repetitions": 8,
                    "average_amplitude_degrees": 91.2,
                    "requires_review": False,
                    "average_duration_seconds": 3.2,
                    "average_velocity_degrees_per_second": 28.5,
                    "average_symmetry_difference_degrees": 7.1,
                    "wellbeing_score": 4,
                    "pain_score": 2,
                    "fatigue_score": 5,
                    "professional_rating": 5,
                    "professional_conduct": "maintain_training",
                    "review_comment": "Manter o ritmo e apoiar o braço se necessário.",
                    "review_visible_to_patient": True,
                    "evidence": [
                        {
                            "event_index": 0,
                            "event_type": "limited_amplitude",
                            "title": "Amplitude abaixo da referência",
                            "timestamp_seconds": 1.5,
                            "content_type": "image/jpeg",
                            "image_base64": base64.b64encode(encoded).decode("ascii"),
                        }
                    ],
                    "movement_events": [
                        {
                            "type": "limited_amplitude",
                            "title": "Amplitude abaixo da referência",
                            "startSeconds": 1.5,
                        }
                    ],
                    "event_reviews": {"limited_amplitude_1500": "confirmed"},
                    "prescription_version": 2,
                    "prescribed_sets": 2,
                    "prescribed_repetitions": 8,
                    "prescribed_sessions_per_week": 3,
                    "prescribed_amplitude_degrees": 90,
                    "prescribed_training_side": "affected",
                    "prescribed_cadence_seconds": 3,
                    "prescribed_rest_seconds": 60,
                },
                {
                    "date": datetime(2026, 10, 8, tzinfo=timezone.utc).isoformat(),
                    "exercise": "Pinça",
                    "status": "completed",
                    "repetitions": 10,
                    "average_distance": 0.074,
                    "requires_review": False,
                }
            ],
        },
    )

    assert response.status_code == 200
    assert response.headers["content-type"] == "application/pdf"
    assert response.content.startswith(b"%PDF")
    assert len(response.content) > 5000
