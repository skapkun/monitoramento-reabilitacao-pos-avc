import math

from app.analysis.exercises.squat import SquatAnalyzer
from app.analysis.models import AnalysisOutcome, Landmark, LandmarkFrame


def squat_frames(angles):
    frames = []
    for index, angle in enumerate(angles):
        radians = math.radians(angle)
        frames.append(
            LandmarkFrame(
                frame_index=index,
                timestamp_seconds=index / 15,
                landmarks={
                    "right_shoulder": Landmark(1, 1, visibility=0.99),
                    "right_hip": Landmark(1, 0, visibility=0.99),
                    "right_knee": Landmark(0, 0, visibility=0.99),
                    "right_ankle": Landmark(
                        math.cos(radians), math.sin(radians), visibility=0.99
                    ),
                },
            )
        )
    return frames


def test_counts_complete_squat_cycles():
    cycle = [170, 160, 140, 110, 95, 90, 110, 140, 160, 170]
    result = SquatAnalyzer().analyze(squat_frames(cycle + cycle))

    assert result.status is AnalysisOutcome.SUCCESS
    assert len(result.repetitions) == 2
    assert result.parameters_version == "squat-v1"
    assert result.average_duration_seconds is not None
    assert len(result.repetition_details) == 2
    assert result.movement_events[0]["type"] == "best_repetition"


def test_squat_is_inconclusive_without_complete_cycle():
    result = SquatAnalyzer().analyze(squat_frames([170] * 20))

    assert result.status is AnalysisOutcome.INCONCLUSIVE
    assert result.repetitions == []
