from dataclasses import asdict, dataclass, field
from enum import Enum
from typing import Dict, List, Optional


class AnalysisOutcome(str, Enum):
    SUCCESS = "success"
    INCONCLUSIVE = "inconclusive"
    FAILED = "failed"


@dataclass(frozen=True)
class Landmark:
    x: float
    y: float
    z: float = 0.0
    visibility: float = 1.0


@dataclass(frozen=True)
class LandmarkFrame:
    frame_index: int
    timestamp_seconds: float
    landmarks: Dict[str, Landmark]


@dataclass(frozen=True)
class Repetition:
    number: int
    start_seconds: float
    end_seconds: float
    minimum_angle_degrees: float
    maximum_angle_degrees: float
    amplitude_degrees: float


@dataclass
class ElbowFlexionResult:
    status: AnalysisOutcome
    message: str
    side: Optional[str]
    confidence: float
    valid_frames: int
    total_frames: int
    detection_ratio: float
    repetitions: List[Repetition] = field(default_factory=list)
    average_amplitude_degrees: Optional[float] = None
    average_duration_seconds: Optional[float] = None
    average_velocity_degrees_per_second: Optional[float] = None
    average_symmetry_difference_degrees: Optional[float] = None
    average_distance: Optional[float] = None
    possible_compensations: List[str] = field(default_factory=list)
    warnings: List[str] = field(default_factory=list)
    parameters_version: str = "elbow-flexion-v1"
    movement_events: List[dict] = field(default_factory=list)
    repetition_details: List[dict] = field(default_factory=list)
    affected_side: Optional[str] = None
    unaffected_side: Optional[str] = None
    average_affected_angle_degrees: Optional[float] = None
    average_unaffected_angle_degrees: Optional[float] = None

    def to_dict(self) -> dict:
        result = asdict(self)
        result["status"] = self.status.value
        return result
