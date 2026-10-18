from dataclasses import dataclass
from pathlib import Path
from typing import Iterator, Tuple

import cv2
import numpy as np


@dataclass(frozen=True)
class VideoFrame:
    index: int
    timestamp_seconds: float
    image_bgr: np.ndarray


class VideoProcessingError(RuntimeError):
    pass


class VideoProcessor:
    def __init__(self, target_fps: float = 15.0, maximum_frames: int = 4500) -> None:
        self.target_fps = target_fps
        self.maximum_frames = maximum_frames

    def frames(self, video_path: Path) -> Iterator[VideoFrame]:
        capture = cv2.VideoCapture(str(video_path))
        if not capture.isOpened():
            raise VideoProcessingError("Não foi possível abrir o arquivo de vídeo.")
        try:
            source_fps = capture.get(cv2.CAP_PROP_FPS)
            source_fps = source_fps if source_fps and source_fps > 0 else self.target_fps
            step = max(1, round(source_fps / self.target_fps))
            source_index = 0
            emitted = 0
            while emitted < self.maximum_frames:
                ok, image = capture.read()
                if not ok:
                    break
                if source_index % step == 0:
                    yield VideoFrame(
                        index=source_index,
                        timestamp_seconds=source_index / source_fps,
                        image_bgr=image,
                    )
                    emitted += 1
                source_index += 1
        finally:
            capture.release()
