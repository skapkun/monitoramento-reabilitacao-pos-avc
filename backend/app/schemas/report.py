from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, Field


class ReportEvidence(BaseModel):
    event_index: int = Field(ge=0, le=3)
    event_type: str = Field(max_length=80)
    title: str = Field(max_length=160)
    timestamp_seconds: float = Field(ge=0)
    content_type: str = Field(pattern=r"^image/jpeg$")
    image_base64: str = Field(max_length=140_000)


class ReportSession(BaseModel):
    date: datetime
    exercise: str = Field(min_length=2, max_length=120)
    status: str = Field(min_length=2, max_length=40)
    repetitions: int = Field(default=0, ge=0, le=10000)
    average_amplitude_degrees: Optional[float] = Field(default=None, ge=0, le=180)
    requires_review: bool = False
    average_duration_seconds: Optional[float] = Field(default=None, ge=0)
    average_velocity_degrees_per_second: Optional[float] = Field(default=None, ge=0)
    average_symmetry_difference_degrees: Optional[float] = Field(
        default=None, ge=0, le=180
    )
    average_distance: Optional[float] = Field(default=None, ge=0)
    wellbeing_score: Optional[int] = Field(default=None, ge=1, le=5)
    pain_score: Optional[int] = Field(default=None, ge=0, le=10)
    fatigue_score: Optional[int] = Field(default=None, ge=0, le=10)
    professional_rating: Optional[int] = Field(default=None, ge=1, le=5)
    professional_conduct: Optional[str] = Field(default=None, max_length=60)
    prescription_version: Optional[int] = Field(default=None, ge=1)
    prescribed_sets: Optional[int] = Field(default=None, ge=1, le=10)
    prescribed_repetitions: Optional[int] = Field(default=None, ge=1, le=100)
    prescribed_sessions_per_week: Optional[int] = Field(default=None, ge=1, le=7)
    prescribed_amplitude_degrees: Optional[float] = Field(default=None, ge=1, le=180)
    prescribed_training_side: Optional[str] = Field(default=None, max_length=20)
    prescribed_cadence_seconds: Optional[float] = Field(default=None, ge=1, le=30)
    prescribed_rest_seconds: Optional[int] = Field(default=None, ge=0, le=600)
    custom_detection_applied: bool = False
    detection_start_threshold: Optional[float] = Field(default=None, ge=0)
    detection_change_threshold: Optional[float] = Field(default=None, ge=0)
    calibration_reason: Optional[str] = Field(default=None, max_length=300)
    movement_events: List[dict] = Field(default_factory=list, max_length=100)
    affected_side: Optional[str] = Field(default=None, max_length=10)
    unaffected_side: Optional[str] = Field(default=None, max_length=10)
    average_affected_angle_degrees: Optional[float] = Field(
        default=None, ge=0, le=180
    )
    average_unaffected_angle_degrees: Optional[float] = Field(
        default=None, ge=0, le=180
    )
    event_reviews: dict = Field(default_factory=dict)
    review_comment: Optional[str] = Field(default=None, max_length=1000)
    review_visible_to_patient: bool = False
    evidence: List[ReportEvidence] = Field(default_factory=list, max_length=4)


class LongitudinalReportRequest(BaseModel):
    patient_name: str = Field(min_length=2, max_length=120)
    patient_id: str = Field(min_length=2, max_length=160)
    sessions: List[ReportSession] = Field(default_factory=list, max_length=500)


class SessionReportRequest(BaseModel):
    patient_name: str = Field(min_length=2, max_length=120)
    patient_id: str = Field(min_length=2, max_length=160)
    session: ReportSession
