from pathlib import Path

import pytest

from app.analysis.video_processor import VideoProcessingError, VideoProcessor


def test_rejects_unreadable_video(tmp_path: Path):
    invalid = tmp_path / "invalid.mp4"
    invalid.write_bytes(b"not a video")
    with pytest.raises(VideoProcessingError):
        list(VideoProcessor().frames(invalid))
