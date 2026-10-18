from dataclasses import dataclass
from statistics import mean
from typing import Dict, List, Optional, Tuple

from app.analysis.metrics import joint_angle_degrees
from app.analysis.models import AnalysisOutcome, ElbowFlexionResult, LandmarkFrame
from app.analysis.repetition_counter import AngleSample, ElbowRepetitionCounter


@dataclass(frozen=True)
class SquatParameters:
    minimum_visibility: float = 0.60
    minimum_valid_frames: int = 15
    minimum_detection_ratio: float = 0.70
    extended_knee_angle_degrees: float = 160.0
    flexed_knee_angle_degrees: float = 100.0
    trunk_inclination_hip_angle_degrees: float = 60.0
    compensation_frame_ratio: float = 0.20


class SquatAnalyzer:
    def __init__(self, parameters: Optional[SquatParameters] = None) -> None:
        self.parameters = parameters or SquatParameters()

    @property
    def parameters_version(self) -> str:
        return (
            "squat-v1"
            if self.parameters == SquatParameters()
            else "squat-v1-custom"
        )

    def analyze(
        self, frames: List[LandmarkFrame], preferred_side: Optional[str] = None
    ) -> ElbowFlexionResult:
        total = len(frames)
        if total == 0:
            return self._inconclusive("O vídeo não produziu frames analisáveis.", None, 0, 0)
        side = preferred_side or self._select_side(frames)
        if side not in {"left", "right"}:
            return self._inconclusive(
                "Não foi possível identificar a perna com visibilidade suficiente.",
                None,
                0,
                total,
            )

        samples: List[AngleSample] = []
        hip_angles: List[float] = []
        valid_frames: List[LandmarkFrame] = []
        for frame in frames:
            points = self._required_points(frame, side)
            if points is None:
                continue
            shoulder, hip, knee, ankle = points
            try:
                knee_angle = joint_angle_degrees(hip, knee, ankle)
                hip_angle = joint_angle_degrees(shoulder, hip, knee)
            except ValueError:
                continue
            samples.append(AngleSample(knee_angle, frame.timestamp_seconds))
            hip_angles.append(hip_angle)
            valid_frames.append(frame)

        valid = len(samples)
        ratio = valid / total
        if valid < self.parameters.minimum_valid_frames:
            return self._inconclusive(
                "Há poucos frames válidos para analisar o agachamento.", side, valid, total
            )
        if ratio < self.parameters.minimum_detection_ratio:
            return self._inconclusive(
                "Quadril, joelho ou tornozelo ficaram invisíveis em parte relevante do vídeo.",
                side,
                valid,
                total,
            )

        repetitions = ElbowRepetitionCounter(
            extended_angle=self.parameters.extended_knee_angle_degrees,
            flexed_angle=self.parameters.flexed_knee_angle_degrees,
        ).count(samples)
        if not repetitions:
            return self._inconclusive(
                "Nenhum ciclo completo de descida e retorno foi observado.", side, valid, total
            )

        durations = [item.end_seconds - item.start_seconds for item in repetitions]
        amplitudes = [item.amplitude_degrees for item in repetitions]
        velocities = [
            item.amplitude_degrees / duration
            for item, duration in zip(repetitions, durations)
            if duration > 0
        ]
        inclined_frames = [
            frame
            for frame, angle in zip(valid_frames, hip_angles)
            if angle < self.parameters.trunk_inclination_hip_angle_degrees
        ]
        inclined = (
            len(inclined_frames) / len(hip_angles)
            >= self.parameters.compensation_frame_ratio
        )
        best = max(repetitions, key=lambda item: item.amplitude_degrees)
        expected = (
            self.parameters.extended_knee_angle_degrees
            - self.parameters.flexed_knee_angle_degrees
        )
        repetition_details = [
            {
                "number": item.number,
                "start_seconds": round(item.start_seconds, 3),
                "end_seconds": round(item.end_seconds, 3),
                "amplitude_degrees": round(item.amplitude_degrees, 2),
                "duration_seconds": round(item.end_seconds - item.start_seconds, 3),
                "classification": (
                    "best"
                    if item.number == best.number
                    else "below_technical_reference"
                    if item.amplitude_degrees < expected * 0.8
                    else "regular"
                ),
            }
            for item in repetitions
        ]
        movement_events = [
            {
                "type": "best_repetition",
                "title": "Maior amplitude observada",
                "description": f"Repetição {best.number}, com amplitude de {best.amplitude_degrees:.1f}°.",
                "start_seconds": round(best.start_seconds, 3),
                "end_seconds": round(best.end_seconds, 3),
                "severity": "positive",
                "repetition": best.number,
            }
        ]
        movement_events.extend(
            {
                "type": "limited_amplitude",
                "title": "Amplitude abaixo da referência técnica",
                "description": f"A repetição {item.number} teve amplitude de {item.amplitude_degrees:.1f}°. Confira com o fisioterapeuta.",
                "start_seconds": round(item.start_seconds, 3),
                "end_seconds": round(item.end_seconds, 3),
                "severity": "attention",
                "repetition": item.number,
            }
            for item in repetitions
            if item.amplitude_degrees < expected * 0.8
        )
        if inclined and inclined_frames:
            movement_events.append(
                {
                    "type": "possible_trunk_inclination",
                    "title": "Possível inclinação do tronco",
                    "description": "O tronco pareceu inclinar durante parte do movimento. Requer revisão profissional.",
                    "start_seconds": round(inclined_frames[0].timestamp_seconds, 3),
                    "end_seconds": round(inclined_frames[-1].timestamp_seconds, 3),
                    "severity": "attention",
                    "repetition": None,
                }
            )
        symmetry, affected_average, unaffected_average = self._bilateral_summary(
            frames, preferred_side
        )
        return ElbowFlexionResult(
            status=AnalysisOutcome.SUCCESS,
            message="Agachamento processado tecnicamente.",
            side=side,
            confidence=round(min(1.0, ratio), 3),
            valid_frames=valid,
            total_frames=total,
            detection_ratio=round(ratio, 3),
            repetitions=repetitions,
            average_amplitude_degrees=round(mean(amplitudes), 2),
            average_duration_seconds=round(mean(durations), 3),
            average_velocity_degrees_per_second=(
                round(mean(velocities), 2) if velocities else None
            ),
            average_symmetry_difference_degrees=(
                round(symmetry, 2) if symmetry is not None else None
            ),
            possible_compensations=["possible_trunk_inclination"] if inclined else [],
            warnings=[
                "Resultado técnico experimental; requer interpretação do fisioterapeuta.",
                "Os limiares utilizados ainda não possuem validação clínica.",
            ],
            parameters_version=self.parameters_version,
            movement_events=movement_events,
            repetition_details=repetition_details,
            affected_side=preferred_side if preferred_side in {"left", "right"} else None,
            unaffected_side=(
                "right" if preferred_side == "left" else "left"
                if preferred_side == "right"
                else None
            ),
            average_affected_angle_degrees=affected_average,
            average_unaffected_angle_degrees=unaffected_average,
        )

    def _select_side(self, frames: List[LandmarkFrame]) -> Optional[str]:
        scores: Dict[str, List[float]] = {"left": [], "right": []}
        for frame in frames:
            for side in scores:
                points = self._required_points(frame, side)
                if points is not None:
                    scores[side].append(min(point.visibility for point in points))
        averages = {side: mean(values) if values else 0.0 for side, values in scores.items()}
        selected = max(averages, key=averages.get)
        return selected if averages[selected] >= self.parameters.minimum_visibility else None

    def _required_points(self, frame: LandmarkFrame, side: str) -> Optional[Tuple]:
        names = [
            f"{side}_shoulder",
            f"{side}_hip",
            f"{side}_knee",
            f"{side}_ankle",
        ]
        if not all(name in frame.landmarks for name in names):
            return None
        points = tuple(frame.landmarks[name] for name in names)
        if min(point.visibility for point in points) < self.parameters.minimum_visibility:
            return None
        return points

    def _bilateral_summary(
        self, frames: List[LandmarkFrame], affected_side: Optional[str]
    ) -> Tuple[Optional[float], Optional[float], Optional[float]]:
        differences: List[float] = []
        affected_angles: List[float] = []
        unaffected_angles: List[float] = []
        for frame in frames:
            left = self._required_points(frame, "left")
            right = self._required_points(frame, "right")
            if left is None or right is None:
                continue
            try:
                left_angle = joint_angle_degrees(left[1], left[2], left[3])
                right_angle = joint_angle_degrees(right[1], right[2], right[3])
            except ValueError:
                continue
            differences.append(abs(left_angle - right_angle))
            if affected_side == "left":
                affected_angles.append(left_angle)
                unaffected_angles.append(right_angle)
            elif affected_side == "right":
                affected_angles.append(right_angle)
                unaffected_angles.append(left_angle)
        return (
            mean(differences) if differences else None,
            round(mean(affected_angles), 2) if affected_angles else None,
            round(mean(unaffected_angles), 2) if unaffected_angles else None,
        )

    def _inconclusive(
        self, message: str, side: Optional[str], valid: int, total: int
    ) -> ElbowFlexionResult:
        return ElbowFlexionResult(
            status=AnalysisOutcome.INCONCLUSIVE,
            message=message,
            side=side,
            confidence=0.0,
            valid_frames=valid,
            total_frames=total,
            detection_ratio=round(valid / total, 3) if total else 0.0,
            warnings=[
                "Tente novamente mantendo ombro, quadril, joelho e tornozelo visíveis."
            ],
            parameters_version=self.parameters_version,
        )
