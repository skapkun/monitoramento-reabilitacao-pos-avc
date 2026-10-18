from typing import Dict, Optional

import cv2
import mediapipe as mp

from app.analysis.models import Landmark


POSE_NAMES = {
    "left_shoulder": 11,
    "right_shoulder": 12,
    "left_elbow": 13,
    "right_elbow": 14,
    "left_wrist": 15,
    "right_wrist": 16,
    "left_hip": 23,
    "right_hip": 24,
    "left_knee": 25,
    "right_knee": 26,
    "left_ankle": 27,
    "right_ankle": 28,
}

HAND_NAMES = {
    "wrist": 0,
    "thumb_tip": 4,
    "index_tip": 8,
}


class MediaPipeProcessingError(RuntimeError):
    pass


class MediaPipePoseExtractor:
    def __init__(self, model_complexity: int = 1, minimum_detection_confidence: float = 0.5) -> None:
        try:
            self._pose = mp.solutions.pose.Pose(
                static_image_mode=False,
                model_complexity=model_complexity,
                enable_segmentation=False,
                min_detection_confidence=minimum_detection_confidence,
                min_tracking_confidence=0.5,
            )
        except RuntimeError as error:
            raise MediaPipeProcessingError(f"Não foi possível inicializar o MediaPipe: {error}") from error

    def extract(self, image_bgr) -> Optional[Dict[str, Landmark]]:
        image_rgb = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2RGB)
        try:
            result = self._pose.process(image_rgb)
        except RuntimeError as error:
            raise MediaPipeProcessingError(f"Falha durante o processamento do MediaPipe: {error}") from error
        if not result.pose_landmarks:
            return None
        landmarks = result.pose_landmarks.landmark
        return {
            name: Landmark(
                x=float(landmarks[index].x),
                y=float(landmarks[index].y),
                z=float(landmarks[index].z),
                visibility=float(landmarks[index].visibility),
            )
            for name, index in POSE_NAMES.items()
        }

    def close(self) -> None:
        self._pose.close()

    def __enter__(self):
        return self

    def __exit__(self, *_args) -> None:
        self.close()


class MediaPipeHandExtractor:
    def __init__(self, minimum_detection_confidence: float = 0.5) -> None:
        try:
            self._hands = mp.solutions.hands.Hands(
                static_image_mode=False,
                max_num_hands=1,
                min_detection_confidence=minimum_detection_confidence,
                min_tracking_confidence=0.5,
            )
        except RuntimeError as error:
            raise MediaPipeProcessingError(
                f"Não foi possível inicializar o MediaPipe Hands: {error}"
            ) from error

    def extract(self, image_bgr) -> Optional[Dict[str, Landmark]]:
        image_rgb = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2RGB)
        try:
            result = self._hands.process(image_rgb)
        except RuntimeError as error:
            raise MediaPipeProcessingError(
                f"Falha durante o processamento do MediaPipe Hands: {error}"
            ) from error
        if not result.multi_hand_landmarks:
            return None
        landmarks = result.multi_hand_landmarks[0].landmark
        return {
            name: Landmark(
                x=float(landmarks[index].x),
                y=float(landmarks[index].y),
                z=float(landmarks[index].z),
                visibility=1.0,
            )
            for name, index in HAND_NAMES.items()
        }

    def close(self) -> None:
        self._hands.close()

    def __enter__(self):
        return self

    def __exit__(self, *_args) -> None:
        self.close()
