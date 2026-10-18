import hashlib
import json
from pathlib import Path

from app.analysis.models import AnalysisOutcome, ElbowFlexionResult
from app.analysis.validation import main, validate_video


class StubPipeline:
    def __init__(self, status: AnalysisOutcome = AnalysisOutcome.SUCCESS):
        self.status = status
        self.received_path = None
        self.received_side = None

    def analyze_video(self, video_path: Path, preferred_side=None):
        self.received_path = video_path
        self.received_side = preferred_side
        return ElbowFlexionResult(
            status=self.status,
            message="resultado controlado",
            side=preferred_side,
            confidence=0.9,
            valid_frames=20,
            total_frames=20,
            detection_ratio=1.0,
        )


def test_validation_report_identifies_video_without_copying_content(tmp_path: Path):
    video = tmp_path / "amostra.mp4"
    content = b"video-controlado"
    video.write_bytes(content)
    pipeline = StubPipeline()

    report = validate_video(video, preferred_side="right", pipeline=pipeline)

    assert report["validationSchema"] == "movere-elbow-validation-v1"
    assert report["video"] == {
        "fileName": "amostra.mp4",
        "sizeBytes": len(content),
        "sha256": hashlib.sha256(content).hexdigest(),
    }
    assert report["result"]["status"] == "success"
    assert pipeline.received_path == video.resolve()
    assert pipeline.received_side == "right"
    assert "video-controlado" not in json.dumps(report)


def test_cli_reports_missing_video(capsys):
    exit_code = main(["arquivo-inexistente.mp4"])

    assert exit_code == 1
    assert "Vídeo não encontrado" in capsys.readouterr().out
