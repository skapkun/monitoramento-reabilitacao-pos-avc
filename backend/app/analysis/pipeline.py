from pathlib import Path
from typing import Callable, Optional

from app.analysis.exercises.elbow_flexion import ElbowFlexionAnalyzer
from app.analysis.exercises.pinch import PinchAnalyzer
from app.analysis.exercises.squat import SquatAnalyzer
from app.analysis.mediapipe_processor import (
    MediaPipeHandExtractor,
    MediaPipePoseExtractor,
    MediaPipeProcessingError,
)
from app.analysis.models import AnalysisOutcome, ElbowFlexionResult, LandmarkFrame
from app.analysis.video_processor import VideoProcessingError, VideoProcessor


class ElbowFlexionPipeline:
    def __init__(
        self,
        video_processor: Optional[VideoProcessor] = None,
        analyzer: Optional[ElbowFlexionAnalyzer] = None,
        extractor_factory: Callable[[], MediaPipePoseExtractor] = MediaPipePoseExtractor,
    ) -> None:
        self.video_processor = video_processor or VideoProcessor()
        self.analyzer = analyzer or ElbowFlexionAnalyzer()
        self.extractor_factory = extractor_factory

    def analyze_video(self, video_path: Path, preferred_side: Optional[str] = None) -> ElbowFlexionResult:
        frames = []
        try:
            with self.extractor_factory() as extractor:
                for video_frame in self.video_processor.frames(video_path):
                    landmarks = extractor.extract(video_frame.image_bgr)
                    frames.append(
                        LandmarkFrame(
                            frame_index=video_frame.index,
                            timestamp_seconds=video_frame.timestamp_seconds,
                            landmarks=landmarks or {},
                        )
                    )
            return self.analyzer.analyze(frames, preferred_side=preferred_side)
        except (VideoProcessingError, MediaPipeProcessingError) as error:
            return ElbowFlexionResult(
                status=AnalysisOutcome.FAILED,
                message=str(error),
                side=preferred_side,
                confidence=0.0,
                valid_frames=0,
                total_frames=0,
                detection_ratio=0.0,
                warnings=["Verifique se o arquivo de vídeo é válido."],
            )


class SquatPipeline:
    def __init__(
        self,
        video_processor: Optional[VideoProcessor] = None,
        analyzer: Optional[SquatAnalyzer] = None,
        extractor_factory: Callable[[], MediaPipePoseExtractor] = MediaPipePoseExtractor,
    ) -> None:
        self.video_processor = video_processor or VideoProcessor()
        self.analyzer = analyzer or SquatAnalyzer()
        self.extractor_factory = extractor_factory

    def analyze_video(
        self, video_path: Path, preferred_side: Optional[str] = None
    ) -> ElbowFlexionResult:
        frames = []
        try:
            with self.extractor_factory() as extractor:
                for video_frame in self.video_processor.frames(video_path):
                    frames.append(
                        LandmarkFrame(
                            frame_index=video_frame.index,
                            timestamp_seconds=video_frame.timestamp_seconds,
                            landmarks=extractor.extract(video_frame.image_bgr) or {},
                        )
                    )
            return self.analyzer.analyze(frames, preferred_side=preferred_side)
        except (VideoProcessingError, MediaPipeProcessingError) as error:
            return _failed_result(str(error), preferred_side, "squat-v1")


class PinchPipeline:
    def __init__(
        self,
        video_processor: Optional[VideoProcessor] = None,
        analyzer: Optional[PinchAnalyzer] = None,
        extractor_factory: Callable[[], MediaPipeHandExtractor] = MediaPipeHandExtractor,
    ) -> None:
        self.video_processor = video_processor or VideoProcessor()
        self.analyzer = analyzer or PinchAnalyzer()
        self.extractor_factory = extractor_factory

    def analyze_video(self, video_path: Path) -> ElbowFlexionResult:
        frames = []
        try:
            with self.extractor_factory() as extractor:
                for video_frame in self.video_processor.frames(video_path):
                    frames.append(
                        LandmarkFrame(
                            frame_index=video_frame.index,
                            timestamp_seconds=video_frame.timestamp_seconds,
                            landmarks=extractor.extract(video_frame.image_bgr) or {},
                        )
                    )
            return self.analyzer.analyze(frames)
        except (VideoProcessingError, MediaPipeProcessingError) as error:
            return _failed_result(str(error), None, "pinch-v1")


def _failed_result(
    message: str, side: Optional[str], parameters_version: str
) -> ElbowFlexionResult:
    return ElbowFlexionResult(
        status=AnalysisOutcome.FAILED,
        message=message,
        side=side,
        confidence=0.0,
        valid_frames=0,
        total_frames=0,
        detection_ratio=0.0,
        warnings=["Verifique se o arquivo de vídeo é válido."],
        parameters_version=parameters_version,
    )
