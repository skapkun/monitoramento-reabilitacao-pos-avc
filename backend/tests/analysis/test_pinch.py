from app.analysis.exercises.pinch import PinchAnalyzer
from app.analysis.models import AnalysisOutcome, Landmark, LandmarkFrame


def pinch_frames(distances):
    return [
        LandmarkFrame(
            frame_index=index,
            timestamp_seconds=index / 15,
            landmarks={
                "thumb_tip": Landmark(0, 0),
                "index_tip": Landmark(distance, 0),
            },
        )
        for index, distance in enumerate(distances)
    ]


def test_counts_complete_pinch_cycles():
    cycle = [0.12, 0.11, 0.08, 0.05, 0.04, 0.07, 0.10, 0.12]
    result = PinchAnalyzer().analyze(pinch_frames(cycle + cycle))

    assert result.status is AnalysisOutcome.SUCCESS
    assert len(result.repetitions) == 2
    assert result.average_distance is not None
    assert result.parameters_version == "pinch-v1"


def test_pinch_is_inconclusive_when_fingers_do_not_close():
    result = PinchAnalyzer().analyze(pinch_frames([0.12] * 20))

    assert result.status is AnalysisOutcome.INCONCLUSIVE
    assert result.repetitions == []
