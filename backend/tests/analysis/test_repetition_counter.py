from app.analysis.repetition_counter import AngleSample, ElbowRepetitionCounter


def samples(angles):
    return [AngleSample(angle=value, timestamp_seconds=index / 10) for index, value in enumerate(angles)]


def test_counts_only_complete_cycles():
    counter = ElbowRepetitionCounter(extended_angle=150, flexed_angle=70)
    result = counter.count(samples([160, 140, 100, 65, 90, 130, 155, 130, 60, 100, 160]))
    assert len(result) == 2
    assert result[0].amplitude_degrees == 95
    assert result[1].amplitude_degrees == 100


def test_ignores_partial_cycle():
    counter = ElbowRepetitionCounter(extended_angle=150, flexed_angle=70)
    assert counter.count(samples([160, 120, 80, 60, 90])) == []
