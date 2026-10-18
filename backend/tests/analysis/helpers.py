import math
from typing import Iterable, List

from app.analysis.models import Landmark, LandmarkFrame


def elbow_frames(
    angles: Iterable[float],
    *,
    side: str = "right",
    visibility: float = 0.99,
    elevated_indices: Iterable[int] = (),
) -> List[LandmarkFrame]:
    elevated = set(elevated_indices)
    frames = []
    for index, angle in enumerate(angles):
        radians = math.radians(angle)
        shoulder_y = -0.2 if index in elevated else 0.0
        landmarks = {
            f"{side}_shoulder": Landmark(1.0, shoulder_y, visibility=visibility),
            f"{side}_elbow": Landmark(0.0, 0.0, visibility=visibility),
            f"{side}_wrist": Landmark(math.cos(radians), math.sin(radians), visibility=visibility),
            f"{side}_hip": Landmark(1.0, 1.0, visibility=visibility),
        }
        other = "left" if side == "right" else "right"
        landmarks.update(
            {
                f"{other}_shoulder": Landmark(0.0, 0.0, visibility=0.1),
                f"{other}_elbow": Landmark(0.0, 0.2, visibility=0.1),
                f"{other}_wrist": Landmark(0.0, 0.4, visibility=0.1),
                f"{other}_hip": Landmark(0.0, 1.0, visibility=0.1),
            }
        )
        frames.append(
            LandmarkFrame(
                frame_index=index,
                timestamp_seconds=index / 15.0,
                landmarks=landmarks,
            )
        )
    return frames
