from pathlib import Path

import cv2
import numpy as np

from app.analysis.models import AnalysisOutcome
from app.analysis.mediapipe_processor import MediaPipeProcessingError
from app.analysis.pipeline import ElbowFlexionPipeline


class EmptyPoseExtractor:
    def extract(self, _image):
        return None

    def __enter__(self):
        return self

    def __exit__(self, *_args):
        return None


def test_full_pipeline_returns_inconclusive_when_pose_is_absent(tmp_path: Path):
    video_path = tmp_path / "blank.avi"
    writer = cv2.VideoWriter(
        str(video_path),
        cv2.VideoWriter_fourcc(*"MJPG"),
        15.0,
        (160, 120),
    )
    assert writer.isOpened()
    for _ in range(20):
        writer.write(np.zeros((120, 160, 3), dtype=np.uint8))
    writer.release()

    result = ElbowFlexionPipeline(extractor_factory=EmptyPoseExtractor).analyze_video(video_path)

    assert result.status is AnalysisOutcome.INCONCLUSIVE
    assert result.total_frames == 20
    assert result.valid_frames == 0
    assert result.confidence == 0


def test_pipeline_reports_mediapipe_initialization_failure(tmp_path: Path):
    def failing_factory():
        raise MediaPipeProcessingError("ambiente gráfico indisponível")

    result = ElbowFlexionPipeline(extractor_factory=failing_factory).analyze_video(tmp_path / "unused.mp4")

    assert result.status is AnalysisOutcome.FAILED
    assert "ambiente gráfico indisponível" in result.message
