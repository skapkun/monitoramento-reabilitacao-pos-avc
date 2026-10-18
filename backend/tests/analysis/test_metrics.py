import pytest

from app.analysis.metrics import joint_angle_degrees
from app.analysis.models import Landmark


@pytest.mark.parametrize("expected,wrist", [(90.0, (0.0, 1.0)), (180.0, (-1.0, 0.0)), (60.0, (0.5, 0.866025))])
def test_joint_angle(expected, wrist):
    result = joint_angle_degrees(
        Landmark(1.0, 0.0),
        Landmark(0.0, 0.0),
        Landmark(*wrist),
    )
    assert result == pytest.approx(expected, abs=0.01)


def test_joint_angle_rejects_coincident_points():
    with pytest.raises(ValueError):
        joint_angle_degrees(Landmark(0, 0), Landmark(0, 0), Landmark(1, 1))
