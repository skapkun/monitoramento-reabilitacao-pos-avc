from dataclasses import dataclass
from statistics import mean
from typing import Dict, List, Optional, Tuple

from app.analysis.metrics import euclidean_distance, joint_angle_degrees
from app.analysis.models import AnalysisOutcome, ElbowFlexionResult, LandmarkFrame
from app.analysis.repetition_counter import AngleSample, ElbowRepetitionCounter


@dataclass(frozen=True)
class ElbowFlexionParameters:
    minimum_visibility: float = 0.60
    minimum_valid_frames: int = 15
    minimum_detection_ratio: float = 0.70
    extended_angle_degrees: float = 160.0
    flexed_angle_degrees: float = 90.0
    shoulder_elevation_torso_ratio: float = 0.12
    compensation_frame_ratio: float = 0.20


class ElbowFlexionAnalyzer:
    def __init__(self, parameters: Optional[ElbowFlexionParameters] = None) -> None:
        self.parameters = parameters or ElbowFlexionParameters()

    @property
    def parameters_version(self) -> str:
        return (
            "elbow-flexion-v1"
            if self.parameters == ElbowFlexionParameters()
            else "elbow-flexion-v1-custom"
        )

    def analyze(self, frames: List[LandmarkFrame], preferred_side: Optional[str] = None) -> ElbowFlexionResult:
        total = len(frames)
        if total == 0:
            return self._inconclusive("O vídeo não produziu frames analisáveis.", None, 0, 0)

        side = preferred_side or self._select_side(frames)
        if side not in {"left", "right"}:
            return self._inconclusive("Não foi possível identificar um braço com visibilidade suficiente.", None, 0, total)

        samples: List[AngleSample] = []
        valid_frames: List[LandmarkFrame] = []
        for frame in frames:
            points = self._required_points(frame, side)
            if points is None:
                continue
            shoulder, elbow, wrist, _hip = points
            try:
                angle = joint_angle_degrees(shoulder, elbow, wrist)
            except ValueError:
                continue
            samples.append(AngleSample(angle=angle, timestamp_seconds=frame.timestamp_seconds))
            valid_frames.append(frame)

        ratio = len(valid_frames) / total
        if len(valid_frames) < self.parameters.minimum_valid_frames:
            return self._inconclusive("Há poucos frames válidos para uma análise confiável.", side, len(valid_frames), total)
        if ratio < self.parameters.minimum_detection_ratio:
            return self._inconclusive("Os pontos do braço ficaram invisíveis em parte relevante do vídeo.", side, len(valid_frames), total)

        counter = ElbowRepetitionCounter(
            extended_angle=self.parameters.extended_angle_degrees,
            flexed_angle=self.parameters.flexed_angle_degrees,
        )
        repetitions = counter.count(samples)
        if not repetitions:
            return self._inconclusive("Nenhum ciclo completo de extensão, flexão e retorno foi observado.", side, len(valid_frames), total)

        compensation_frames = self._shoulder_elevation_frames(valid_frames, side)
        compensation = bool(compensation_frames) and (
            len(compensation_frames) / len(valid_frames)
            >= self.parameters.compensation_frame_ratio
        )
        amplitudes = [rep.amplitude_degrees for rep in repetitions]
        durations = [rep.end_seconds - rep.start_seconds for rep in repetitions]
        velocities = [
            rep.amplitude_degrees / duration
            for rep, duration in zip(repetitions, durations)
            if duration > 0
        ]
        symmetry, affected_average, unaffected_average = self._bilateral_summary(
            frames, preferred_side
        )
        repetition_details = self._repetition_details(repetitions)
        movement_events = self._movement_events(
            repetitions, compensation_frames if compensation else []
        )
        confidence = min(1.0, ratio * min(1.0, len(valid_frames) / (self.parameters.minimum_valid_frames * 2)))
        warnings = [
            "Resultado técnico experimental; requer interpretação do fisioterapeuta.",
            "Os limiares utilizados ainda não possuem validação clínica.",
        ]
        return ElbowFlexionResult(
            status=AnalysisOutcome.SUCCESS,
            message="Movimento processado tecnicamente.",
            side=side,
            confidence=round(confidence, 3),
            valid_frames=len(valid_frames),
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
            possible_compensations=["possible_shoulder_elevation"] if compensation else [],
            warnings=warnings,
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
            parameters_version=self.parameters_version,
        )

    def _select_side(self, frames: List[LandmarkFrame]) -> Optional[str]:
        scores: Dict[str, List[float]] = {"left": [], "right": []}
        for frame in frames:
            for side in scores:
                names = [f"{side}_shoulder", f"{side}_elbow", f"{side}_wrist", f"{side}_hip"]
                if all(name in frame.landmarks for name in names):
                    scores[side].append(min(frame.landmarks[name].visibility for name in names))
        averages = {side: mean(values) if values else 0.0 for side, values in scores.items()}
        selected = max(averages, key=averages.get)
        return selected if averages[selected] >= self.parameters.minimum_visibility else None

    def _required_points(self, frame: LandmarkFrame, side: str) -> Optional[Tuple]:
        names = [f"{side}_shoulder", f"{side}_elbow", f"{side}_wrist", f"{side}_hip"]
        if not all(name in frame.landmarks for name in names):
            return None
        points = tuple(frame.landmarks[name] for name in names)
        if min(point.visibility for point in points) < self.parameters.minimum_visibility:
            return None
        return points

    def _shoulder_elevation_frames(
        self, frames: List[LandmarkFrame], side: str
    ) -> List[LandmarkFrame]:
        samples: List[Tuple[LandmarkFrame, float]] = []
        for frame in frames:
            shoulder = frame.landmarks[f"{side}_shoulder"]
            hip = frame.landmarks[f"{side}_hip"]
            torso = euclidean_distance(shoulder, hip)
            if torso > 1e-6:
                samples.append((frame, shoulder.y / torso))
        if len(samples) < self.parameters.minimum_valid_frames:
            return []
        baseline = mean(value for _, value in samples[: min(10, len(samples))])
        return [
            frame
            for frame, value in samples
            if baseline - value >= self.parameters.shoulder_elevation_torso_ratio
        ]

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
                left_angle = joint_angle_degrees(left[0], left[1], left[2])
                right_angle = joint_angle_degrees(right[0], right[1], right[2])
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

    def _repetition_details(self, repetitions) -> List[dict]:
        best = max(repetitions, key=lambda item: item.amplitude_degrees)
        expected = (
            self.parameters.extended_angle_degrees
            - self.parameters.flexed_angle_degrees
        )
        return [
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

    def _movement_events(
        self, repetitions, compensation_frames: List[LandmarkFrame]
    ) -> List[dict]:
        best = max(repetitions, key=lambda item: item.amplitude_degrees)
        events = [
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
        expected = (
            self.parameters.extended_angle_degrees
            - self.parameters.flexed_angle_degrees
        )
        for item in repetitions:
            if item.amplitude_degrees < expected * 0.8:
                events.append(
                    {
                        "type": "limited_amplitude",
                        "title": "Amplitude abaixo da referência técnica",
                        "description": f"A repetição {item.number} teve amplitude de {item.amplitude_degrees:.1f}°. Confira com o fisioterapeuta.",
                        "start_seconds": round(item.start_seconds, 3),
                        "end_seconds": round(item.end_seconds, 3),
                        "severity": "attention",
                        "repetition": item.number,
                    }
                )
        if compensation_frames:
            events.append(
                {
                    "type": "possible_shoulder_elevation",
                    "title": "Possível elevação do ombro",
                    "description": "O ombro pareceu subir durante parte do movimento. Requer revisão profissional.",
                    "start_seconds": round(compensation_frames[0].timestamp_seconds, 3),
                    "end_seconds": round(compensation_frames[-1].timestamp_seconds, 3),
                    "severity": "attention",
                    "repetition": None,
                }
            )
        return events

    def _inconclusive(self, message: str, side: Optional[str], valid: int, total: int) -> ElbowFlexionResult:
        ratio = valid / total if total else 0.0
        return ElbowFlexionResult(
            status=AnalysisOutcome.INCONCLUSIVE,
            message=message,
            side=side,
            confidence=0.0,
            valid_frames=valid,
            total_frames=total,
            detection_ratio=round(ratio, 3),
            warnings=["Tente novamente com o braço inteiro visível e iluminação adequada."],
            parameters_version=self.parameters_version,
        )
