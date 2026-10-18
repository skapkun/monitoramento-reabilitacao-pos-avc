from dataclasses import dataclass
from enum import Enum
from typing import List, Optional

from app.analysis.models import Repetition


class MovementPhase(str, Enum):
    UNKNOWN = "unknown"
    EXTENDED = "extended"
    FLEXED = "flexed"


@dataclass(frozen=True)
class AngleSample:
    angle: float
    timestamp_seconds: float


class ElbowRepetitionCounter:
    def __init__(self, extended_angle: float, flexed_angle: float) -> None:
        if flexed_angle >= extended_angle:
            raise ValueError("flexed_angle deve ser menor que extended_angle")
        self.extended_angle = extended_angle
        self.flexed_angle = flexed_angle

    def count(self, samples: List[AngleSample]) -> List[Repetition]:
        phase = MovementPhase.UNKNOWN
        start: Optional[AngleSample] = None
        cycle: List[AngleSample] = []
        repetitions: List[Repetition] = []

        for sample in samples:
            if phase is MovementPhase.UNKNOWN:
                if sample.angle >= self.extended_angle:
                    phase = MovementPhase.EXTENDED
                    start = sample
                    cycle = [sample]
                continue

            cycle.append(sample)
            if phase is MovementPhase.EXTENDED and sample.angle <= self.flexed_angle:
                phase = MovementPhase.FLEXED
            elif phase is MovementPhase.FLEXED and sample.angle >= self.extended_angle:
                angles = [item.angle for item in cycle]
                minimum = min(angles)
                maximum = max(angles)
                repetitions.append(
                    Repetition(
                        number=len(repetitions) + 1,
                        start_seconds=start.timestamp_seconds if start else 0.0,
                        end_seconds=sample.timestamp_seconds,
                        minimum_angle_degrees=round(minimum, 2),
                        maximum_angle_degrees=round(maximum, 2),
                        amplitude_degrees=round(maximum - minimum, 2),
                    )
                )
                phase = MovementPhase.EXTENDED
                start = sample
                cycle = [sample]

        return repetitions
