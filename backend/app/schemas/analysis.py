from __future__ import annotations

from datetime import datetime, timezone
from enum import Enum
from typing import List, Optional, Union
from uuid import UUID

from pydantic import BaseModel, Field


class ExerciseType(str, Enum):
    elbow_flexion = "elbow_flexion"
    squat = "squat"
    pinch = "pinch"


class AnalysisStatus(str, Enum):
    processing = "processing"
    completed = "completed"
    failed = "failed"
    inconclusive = "inconclusive"


class MovementEvent(BaseModel):
    type: str
    title: str
    description: str
    start_seconds: float = Field(ge=0)
    end_seconds: float = Field(ge=0)
    severity: str = "information"
    repetition: Optional[int] = Field(default=None, ge=1)


class RepetitionDetail(BaseModel):
    number: int = Field(ge=1)
    start_seconds: float = Field(ge=0)
    end_seconds: float = Field(ge=0)
    amplitude_degrees: float = Field(ge=0)
    duration_seconds: float = Field(ge=0)
    classification: str


class AnalysisEvidence(BaseModel):
    event_index: int = Field(ge=0, le=3)
    event_type: str = Field(max_length=80)
    title: str = Field(max_length=160)
    timestamp_seconds: float = Field(ge=0)
    content_type: str = "image/jpeg"
    image_base64: str = Field(max_length=140_000)


class AnalysisMetrics(BaseModel):
    repetitions: int = Field(ge=0)
    source: str
    confidence: Optional[float] = Field(default=None, ge=0, le=1)
    average_amplitude_degrees: Optional[float] = Field(default=None, ge=0, le=180)
    average_duration_seconds: Optional[float] = Field(default=None, ge=0)
    average_velocity_degrees_per_second: Optional[float] = Field(default=None, ge=0)
    average_symmetry_difference_degrees: Optional[float] = Field(
        default=None, ge=0, le=180
    )
    average_distance: Optional[float] = Field(default=None, ge=0)
    parameters_version: Optional[str] = None
    valid_frames: Optional[int] = Field(default=None, ge=0)
    total_frames: Optional[int] = Field(default=None, ge=0)
    detection_ratio: Optional[float] = Field(default=None, ge=0, le=1)
    analyzed_side: Optional[str] = None
    possible_compensations: List[str] = Field(default_factory=list)
    warnings: List[str] = Field(default_factory=list)
    movement_events: List[MovementEvent] = Field(default_factory=list)
    repetition_details: List[RepetitionDetail] = Field(default_factory=list)
    evidence: List[AnalysisEvidence] = Field(default_factory=list, max_length=4)
    affected_side: Optional[str] = None
    unaffected_side: Optional[str] = None
    average_affected_angle_degrees: Optional[float] = Field(
        default=None, ge=0, le=180
    )
    average_unaffected_angle_degrees: Optional[float] = Field(
        default=None, ge=0, le=180
    )


class AnalysisResult(BaseModel):
    analysis_id: UUID
    session_id: UUID
    exercise_type: ExerciseType
    status: AnalysisStatus
    simulated: bool
    message: str
    technical_issue_code: Optional[str] = None
    created_at: datetime
    metrics: Optional[AnalysisMetrics] = None


class AnalysisAccepted(BaseModel):
    analysis_id: UUID
    session_id: UUID
    exercise_type: ExerciseType
    status: AnalysisStatus
    simulated: bool
    message: str


class ApiResponse(BaseModel):
    status: str = "success"
    data: Union[AnalysisAccepted, AnalysisResult]
    message: str


def utc_now() -> datetime:
    return datetime.now(timezone.utc)
