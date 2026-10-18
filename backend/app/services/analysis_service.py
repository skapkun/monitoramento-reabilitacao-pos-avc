from __future__ import annotations

import logging
from pathlib import Path
from threading import Lock
from typing import Dict, Optional
from uuid import UUID, uuid4

from app.analysis.models import AnalysisOutcome
from app.analysis.pipeline import ElbowFlexionPipeline, PinchPipeline, SquatPipeline
from app.analysis.exercises.elbow_flexion import ElbowFlexionAnalyzer, ElbowFlexionParameters
from app.analysis.exercises.pinch import PinchAnalyzer, PinchParameters
from app.analysis.exercises.squat import SquatAnalyzer, SquatParameters
from app.schemas.analysis import (
    AnalysisAccepted,
    AnalysisMetrics,
    AnalysisResult,
    AnalysisStatus,
    ExerciseType,
    utc_now,
)
from app.services.evidence_service import EvidenceService


logger = logging.getLogger(__name__)


class AnalysisService:
    def __init__(
        self,
        mode: str = "mock",
        pipeline: Optional[ElbowFlexionPipeline] = None,
        evidence_service: Optional[EvidenceService] = None,
    ) -> None:
        if mode not in {"mock", "real"}:
            raise ValueError("ANALYSIS_MODE deve ser 'mock' ou 'real'.")
        self.mode = mode
        self._pipeline = pipeline
        self._evidence_service = evidence_service or EvidenceService()
        self._results: Dict[UUID, AnalysisResult] = {}
        self._lock = Lock()

    @property
    def simulated(self) -> bool:
        return self.mode == "mock"

    def create(self, session_id: UUID, exercise_type: ExerciseType) -> AnalysisAccepted:
        analysis_id = uuid4()
        result = AnalysisResult(
            analysis_id=analysis_id,
            session_id=session_id,
            exercise_type=exercise_type,
            status=AnalysisStatus.processing,
            simulated=self.simulated,
            message="Vídeo recebido e aguardando processamento.",
            created_at=utc_now(),
        )
        with self._lock:
            self._results[analysis_id] = result
        return AnalysisAccepted(
            analysis_id=analysis_id,
            session_id=session_id,
            exercise_type=exercise_type,
            status=AnalysisStatus.processing,
            simulated=self.simulated,
            message=result.message,
        )

    def process(
        self,
        analysis_id: UUID,
        video_path: Path,
        affected_side: Optional[str] = None,
        thresholds: Optional[tuple[float, float]] = None,
    ) -> None:
        try:
            current = self.get(analysis_id)
            if current is None:
                return
            if self.simulated:
                result = current.model_copy(
                    update={
                        "status": AnalysisStatus.completed,
                        "message": "Resultado simulado. Nenhuma análise de movimento foi executada.",
                        "metrics": AnalysisMetrics(repetitions=8, source="mock"),
                    }
                )
            else:
                pipeline = self._pipeline or self._pipeline_for(
                    current.exercise_type, thresholds
                )
                if self._pipeline is not None or current.exercise_type is ExerciseType.pinch:
                    technical = pipeline.analyze_video(video_path)
                else:
                    technical = pipeline.analyze_video(
                        video_path, preferred_side=affected_side
                    )
                status = {
                    AnalysisOutcome.SUCCESS: AnalysisStatus.completed,
                    AnalysisOutcome.INCONCLUSIVE: AnalysisStatus.inconclusive,
                    AnalysisOutcome.FAILED: AnalysisStatus.failed,
                }[technical.status]
                metrics = None
                if technical.status is AnalysisOutcome.SUCCESS:
                    evidence = self._evidence_service.capture(
                        video_path, technical.movement_events
                    )
                    metrics = AnalysisMetrics(
                        repetitions=len(technical.repetitions),
                        source="computer_vision",
                        confidence=technical.confidence,
                        average_amplitude_degrees=technical.average_amplitude_degrees,
                        average_duration_seconds=technical.average_duration_seconds,
                        average_velocity_degrees_per_second=technical.average_velocity_degrees_per_second,
                        average_symmetry_difference_degrees=technical.average_symmetry_difference_degrees,
                        average_distance=technical.average_distance,
                        parameters_version=technical.parameters_version,
                        valid_frames=technical.valid_frames,
                        total_frames=technical.total_frames,
                        detection_ratio=technical.detection_ratio,
                        analyzed_side=technical.side,
                        possible_compensations=technical.possible_compensations,
                        warnings=technical.warnings,
                        movement_events=technical.movement_events,
                        repetition_details=technical.repetition_details,
                        evidence=evidence,
                        affected_side=technical.affected_side,
                        unaffected_side=technical.unaffected_side,
                        average_affected_angle_degrees=technical.average_affected_angle_degrees,
                        average_unaffected_angle_degrees=technical.average_unaffected_angle_degrees,
                    )
                result = current.model_copy(
                    update={
                        "status": status,
                        "message": technical.message,
                        "metrics": metrics,
                        "technical_issue_code": self._issue_code(technical),
                    }
                )
            self._set(result)
        except Exception:
            logger.exception("Falha técnica no job de análise %s", analysis_id)
            current = self.get(analysis_id)
            if current is not None:
                self._set(
                    current.model_copy(
                        update={
                            "status": AnalysisStatus.failed,
                            "message": "Ocorreu uma falha técnica durante o processamento.",
                        }
                    )
                )
        finally:
            video_path.unlink(missing_ok=True)

    @staticmethod
    def validate_calibration(
        exercise_type: ExerciseType,
        start: Optional[float],
        change: Optional[float],
    ) -> Optional[tuple[float, float]]:
        if start is None and change is None:
            return None
        if start is None or change is None:
            raise ValueError("Informe os dois limiares da calibração.")
        if exercise_type is ExerciseType.pinch:
            if not 0.06 <= start <= 0.20 or not 0.01 <= change <= 0.09:
                raise ValueError("Os limiares da pinça estão fora dos limites permitidos.")
            if start - change < 0.02:
                raise ValueError("A diferença entre abertura e fechamento deve ser de pelo menos 0,02.")
        else:
            if not 120 <= start <= 175 or not 40 <= change <= 140:
                raise ValueError("Os limiares angulares estão fora dos limites permitidos.")
            if start - change < 20:
                raise ValueError("A diferença entre os limiares angulares deve ser de pelo menos 20°.")
        return (start, change)

    def _pipeline_for(
        self,
        exercise_type: ExerciseType,
        thresholds: Optional[tuple[float, float]] = None,
    ):
        if exercise_type is ExerciseType.elbow_flexion:
            parameters = (
                ElbowFlexionParameters(
                    extended_angle_degrees=thresholds[0],
                    flexed_angle_degrees=thresholds[1],
                )
                if thresholds
                else None
            )
            return ElbowFlexionPipeline(analyzer=ElbowFlexionAnalyzer(parameters))
        if exercise_type is ExerciseType.squat:
            parameters = (
                SquatParameters(
                    extended_knee_angle_degrees=thresholds[0],
                    flexed_knee_angle_degrees=thresholds[1],
                )
                if thresholds
                else None
            )
            return SquatPipeline(analyzer=SquatAnalyzer(parameters))
        parameters = (
            PinchParameters(open_distance=thresholds[0], closed_distance=thresholds[1])
            if thresholds
            else None
        )
        return PinchPipeline(analyzer=PinchAnalyzer(parameters))

    def get(self, analysis_id: UUID) -> Optional[AnalysisResult]:
        with self._lock:
            return self._results.get(analysis_id)

    @staticmethod
    def _issue_code(technical) -> Optional[str]:
        if technical.status is AnalysisOutcome.SUCCESS:
            return None
        if technical.status is AnalysisOutcome.FAILED:
            return "technical_failure"
        message = technical.message.lower()
        if "poucos frames" in message or "frames analisáveis" in message:
            return "insufficient_frames"
        if "invis" in message or "visibilidade" in message:
            return "low_visibility"
        if "nenhum ciclo completo" in message:
            return "no_complete_cycle"
        return "inconclusive_analysis"

    def _set(self, result: AnalysisResult) -> None:
        with self._lock:
            self._results[result.analysis_id] = result
