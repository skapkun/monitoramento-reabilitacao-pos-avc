from pathlib import Path

import cv2
import numpy as np

from app.services.evidence_service import EvidenceService


def make_video(path: Path) -> None:
    writer = cv2.VideoWriter(
        str(path), cv2.VideoWriter_fourcc(*"MJPG"), 10, (320, 240)
    )
    for index in range(20):
        frame = np.full((240, 320, 3), (index * 10) % 255, dtype=np.uint8)
        writer.write(frame)
    writer.release()


def test_extracts_limited_compressed_evidence(tmp_path: Path) -> None:
    video = tmp_path / "movement.avi"
    make_video(video)
    events = [
        {
            "type": "best_repetition",
            "title": "Melhor execução",
            "start_seconds": 0.5,
        },
        {
            "type": "possible_compensation",
            "title": "Possível compensação",
            "start_seconds": 1.0,
        },
    ]

    evidence = EvidenceService().capture(video, events)

    assert len(evidence) == 2
    assert evidence[0].title == "Melhor execução"
    assert evidence[0].content_type == "image/jpeg"
    assert len(evidence[0].image_base64) < 140_000
