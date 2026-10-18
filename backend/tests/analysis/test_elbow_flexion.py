from app.analysis.exercises.elbow_flexion import ElbowFlexionAnalyzer
from app.analysis.models import AnalysisOutcome
from tests.analysis.helpers import elbow_frames


CYCLE = [160, 160, 145, 120, 90, 65, 60, 80, 110, 140, 155, 160]


def test_analyzes_two_complete_repetitions_and_selects_visible_side():
    result = ElbowFlexionAnalyzer().analyze(elbow_frames(CYCLE + CYCLE))
    assert result.status is AnalysisOutcome.SUCCESS
    assert result.side == "right"
    assert len(result.repetitions) == 2
    assert result.average_amplitude_degrees == 100
    assert result.detection_ratio == 1
    assert result.confidence > 0
    assert len(result.repetition_details) == 2
    assert result.repetition_details[0]["classification"] == "best"
    assert result.movement_events[0]["type"] == "best_repetition"


def test_reports_possible_shoulder_elevation_without_clinical_claim():
    angles = CYCLE + CYCLE
    elevated = range(10, 18)
    result = ElbowFlexionAnalyzer().analyze(elbow_frames(angles, elevated_indices=elevated))
    assert result.status is AnalysisOutcome.SUCCESS
    assert result.possible_compensations == ["possible_shoulder_elevation"]
    assert any(
        event["type"] == "possible_shoulder_elevation"
        for event in result.movement_events
    )
    assert any("não possuem validação clínica" in warning for warning in result.warnings)


def test_is_inconclusive_when_visibility_is_low():
    result = ElbowFlexionAnalyzer().analyze(elbow_frames(CYCLE + CYCLE, visibility=0.3))
    assert result.status is AnalysisOutcome.INCONCLUSIVE
    assert result.confidence == 0
    assert result.repetitions == []


def test_is_inconclusive_with_too_few_frames():
    result = ElbowFlexionAnalyzer().analyze(elbow_frames(CYCLE[:8]))
    assert result.status is AnalysisOutcome.INCONCLUSIVE
    assert "poucos frames" in result.message


def test_is_inconclusive_without_complete_cycle():
    result = ElbowFlexionAnalyzer().analyze(elbow_frames([160] * 20))
    assert result.status is AnalysisOutcome.INCONCLUSIVE
    assert "Nenhum ciclo completo" in result.message
