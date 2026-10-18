from dataclasses import dataclass
from statistics import mean
from typing import List, Optional

from app.analysis.metrics import euclidean_distance
from app.analysis.models import (
    AnalysisOutcome,
    ElbowFlexionResult,
    LandmarkFrame,
    Repetition,
)


@dataclass(frozen=True)
class PinchParameters:
    closed_distance: float = 0.05
    open_distance: float = 0.10
    minimum_valid_frames: int = 15
    minimum_detection_ratio: float = 0.70


class PinchAnalyzer:
    def __init__(self, parameters: Optional[PinchParameters] = None) -> None:
        self.parameters = parameters or PinchParameters()

    @property
    def parameters_version(self) -> str:
        return (
            "pinch-v1"
            if self.parameters == PinchParameters()
            else "pinch-v1-custom"
        )

    def analyze(self, frames: List[LandmarkFrame]) -> ElbowFlexionResult:
        total = len(frames)
        samples = []
        for frame in frames:
            thumb = frame.landmarks.get("thumb_tip")
            index = frame.landmarks.get("index_tip")
            if thumb is not None and index is not None:
                samples.append(
                    (frame.timestamp_seconds, euclidean_distance(thumb, index))
                )
        valid = len(samples)
        ratio = valid / total if total else 0.0
        if valid < self.parameters.minimum_valid_frames or ratio < self.parameters.minimum_detection_ratio:
            return self._inconclusive(
                "Polegar e indicador não permaneceram visíveis por tempo suficiente.",
                valid,
                total,
            )

        repetitions: List[Repetition] = []
        state = "waiting_open"
        start = 0.0
        minimum = 1.0
        maximum = 0.0
        for timestamp, distance in samples:
            if state == "waiting_open" and distance >= self.parameters.open_distance:
                state = "open"
                start = timestamp
                minimum = distance
                maximum = distance
            elif state == "open":
                minimum = min(minimum, distance)
                maximum = max(maximum, distance)
                if distance <= self.parameters.closed_distance:
                    state = "closed"
            elif state == "closed":
                minimum = min(minimum, distance)
                maximum = max(maximum, distance)
                if distance >= self.parameters.open_distance:
                    repetitions.append(
                        Repetition(
                            number=len(repetitions) + 1,
                            start_seconds=start,
                            end_seconds=timestamp,
                            minimum_angle_degrees=minimum,
                            maximum_angle_degrees=maximum,
                            amplitude_degrees=maximum - minimum,
                        )
                    )
                    state = "open"
                    start = timestamp
                    minimum = distance
                    maximum = distance

        if not repetitions:
            return self._inconclusive(
                "Nenhum ciclo completo de abertura, fechamento e reabertura foi observado.",
                valid,
                total,
            )
        durations = [item.end_seconds - item.start_seconds for item in repetitions]
        best = max(repetitions, key=lambda item: item.amplitude_degrees)
        repetition_details = [
            {
                "number": item.number,
                "start_seconds": round(item.start_seconds, 3),
                "end_seconds": round(item.end_seconds, 3),
                "amplitude_degrees": round(item.amplitude_degrees, 4),
                "duration_seconds": round(item.end_seconds - item.start_seconds, 3),
                "classification": "best" if item.number == best.number else "regular",
            }
            for item in repetitions
        ]
        return ElbowFlexionResult(
            status=AnalysisOutcome.SUCCESS,
            message="Movimento de pinça processado tecnicamente.",
            side=None,
            confidence=round(min(1.0, ratio), 3),
            valid_frames=valid,
            total_frames=total,
            detection_ratio=round(ratio, 3),
            repetitions=repetitions,
            average_duration_seconds=round(mean(durations), 3),
            average_distance=round(mean(distance for _, distance in samples), 4),
            warnings=[
                "Resultado técnico experimental; requer interpretação profissional.",
                "A distância é normalizada na imagem 2D e não representa medida física.",
            ],
            parameters_version=self.parameters_version,
            repetition_details=repetition_details,
            movement_events=[
                {
                    "type": "best_repetition",
                    "title": "Maior abertura observada",
                    "description": f"Repetição {best.number}, com variação normalizada de {best.amplitude_degrees:.3f}.",
                    "start_seconds": round(best.start_seconds, 3),
                    "end_seconds": round(best.end_seconds, 3),
                    "severity": "positive",
                    "repetition": best.number,
                }
            ],
        )

    def _inconclusive(
        self, message: str, valid: int, total: int
    ) -> ElbowFlexionResult:
        return ElbowFlexionResult(
            status=AnalysisOutcome.INCONCLUSIVE,
            message=message,
            side=None,
            confidence=0.0,
            valid_frames=valid,
            total_frames=total,
            detection_ratio=round(valid / total, 3) if total else 0.0,
            warnings=["Tente novamente mantendo polegar e indicador visíveis."],
            parameters_version=self.parameters_version,
        )
