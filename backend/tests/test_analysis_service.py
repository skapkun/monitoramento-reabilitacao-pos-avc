from pathlib import Path
from uuid import uuid4

from app.analysis.models import AnalysisOutcome, ElbowFlexionResult, Repetition
from app.schemas.analysis import AnalysisStatus, ExerciseType
from app.services.analysis_service import AnalysisService


class SuccessfulPipeline:
    def analyze_video(self, _path: Path) -> ElbowFlexionResult:
        return ElbowFlexionResult(
            status=AnalysisOutcome.SUCCESS,
            message="Movimento processado tecnicamente.",
            side="right",
            confidence=0.91,
            valid_frames=90,
            total_frames=100,
            detection_ratio=0.9,
            repetitions=[
                Repetition(
                    number=1,
                    start_seconds=0,
                    end_seconds=2,
                    minimum_angle_degrees=60,
                    maximum_angle_degrees=160,
                    amplitude_degrees=100,
                )
            ],
            average_amplitude_degrees=100,
            warnings=["Resultado técnico experimental."],
        )


class InconclusivePipeline:
    def analyze_video(self, _path: Path) -> ElbowFlexionResult:
        return ElbowFlexionResult(
            status=AnalysisOutcome.INCONCLUSIVE,
            message="Há poucos frames válidos.",
            side="left",
            confidence=0,
            valid_frames=4,
            total_frames=20,
            detection_ratio=0.2,
        )


def make_video(tmp_path: Path) -> Path:
    path = tmp_path / "video.mp4"
    path.write_bytes(b"temporary-video")
    return path


def test_real_service_maps_metrics_and_removes_temporary_video(tmp_path: Path) -> None:
    service = AnalysisService(mode="real", pipeline=SuccessfulPipeline())
    accepted = service.create(uuid4(), ExerciseType.elbow_flexion)
    video = make_video(tmp_path)

    service.process(accepted.analysis_id, video)

    result = service.get(accepted.analysis_id)
    assert result is not None
    assert result.status is AnalysisStatus.completed
    assert result.simulated is False
    assert result.metrics is not None
    assert result.metrics.repetitions == 1
    assert result.metrics.source == "computer_vision"
    assert result.metrics.average_amplitude_degrees == 100
    assert result.technical_issue_code is None
    assert video.exists() is False


def test_real_service_preserves_inconclusive_without_metrics(tmp_path: Path) -> None:
    service = AnalysisService(mode="real", pipeline=InconclusivePipeline())
    accepted = service.create(uuid4(), ExerciseType.elbow_flexion)
    video = make_video(tmp_path)

    service.process(accepted.analysis_id, video)

    result = service.get(accepted.analysis_id)
    assert result is not None
    assert result.status is AnalysisStatus.inconclusive
    assert result.metrics is None
    assert result.message == "Há poucos frames válidos."
    assert result.technical_issue_code == "insufficient_frames"
    assert video.exists() is False


def test_rejects_unknown_analysis_mode() -> None:
    try:
        AnalysisService(mode="invalid")
    except ValueError as error:
        assert "ANALYSIS_MODE" in str(error)
    else:
        raise AssertionError("Modo inválido deveria ser rejeitado")


def test_calibration_validation_accepts_controlled_ranges() -> None:
    assert AnalysisService.validate_calibration(
        ExerciseType.elbow_flexion, 150, 80
    ) == (150, 80)
    assert AnalysisService.validate_calibration(
        ExerciseType.pinch, 0.12, 0.05
    ) == (0.12, 0.05)

    service = AnalysisService(mode="real")
    elbow_pipeline = service._pipeline_for(ExerciseType.elbow_flexion, (150, 80))
    assert elbow_pipeline.analyzer.parameters.extended_angle_degrees == 150
    assert elbow_pipeline.analyzer.parameters.flexed_angle_degrees == 80
    assert elbow_pipeline.analyzer.parameters_version.endswith("-custom")
