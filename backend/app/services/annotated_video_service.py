from __future__ import annotations

import tempfile
from pathlib import Path
from typing import Callable, Optional

import cv2

from app.analysis.mediapipe_processor import (
    MediaPipeHandExtractor,
    MediaPipePoseExtractor,
)
from app.analysis.metrics import euclidean_distance, joint_angle_degrees
from app.analysis.models import Landmark
from app.schemas.analysis import ExerciseType


class AnnotatedVideoError(RuntimeError):
    pass


class AnnotatedVideoService:
    def __init__(
        self,
        pose_extractor_factory: Callable[[], MediaPipePoseExtractor] = MediaPipePoseExtractor,
        hand_extractor_factory: Callable[[], MediaPipeHandExtractor] = MediaPipeHandExtractor,
    ) -> None:
        self.pose_extractor_factory = pose_extractor_factory
        self.hand_extractor_factory = hand_extractor_factory

    def render(
        self,
        content: bytes,
        exercise_type: ExerciseType,
        analyzed_side: Optional[str] = None,
    ) -> bytes:
        source = tempfile.NamedTemporaryFile(suffix=".mp4", delete=False)
        output_path = Path(source.name).with_name(f"{Path(source.name).stem}-annotated.mp4")
        source_path = Path(source.name)
        try:
            with source:
                source.write(content)
            self._render_file(source_path, output_path, exercise_type, analyzed_side)
            rendered = output_path.read_bytes()
            if not rendered:
                raise AnnotatedVideoError("O vídeo anotado ficou vazio.")
            return rendered
        finally:
            source_path.unlink(missing_ok=True)
            output_path.unlink(missing_ok=True)

    def _render_file(
        self,
        source_path: Path,
        output_path: Path,
        exercise_type: ExerciseType,
        analyzed_side: Optional[str],
    ) -> None:
        capture = cv2.VideoCapture(str(source_path))
        if not capture.isOpened():
            raise AnnotatedVideoError("Não foi possível abrir o vídeo original.")
        width = int(capture.get(cv2.CAP_PROP_FRAME_WIDTH))
        height = int(capture.get(cv2.CAP_PROP_FRAME_HEIGHT))
        fps = capture.get(cv2.CAP_PROP_FPS)
        fps = fps if fps and fps > 0 else 15.0
        writer = cv2.VideoWriter(
            str(output_path),
            cv2.VideoWriter_fourcc(*"mp4v"),
            fps,
            (width, height),
        )
        if not writer.isOpened():
            capture.release()
            raise AnnotatedVideoError("Não foi possível criar o vídeo anotado.")
        extractor_factory = (
            self.hand_extractor_factory
            if exercise_type is ExerciseType.pinch
            else self.pose_extractor_factory
        )
        counter = _LiveCounter(exercise_type)
        try:
            with extractor_factory() as extractor:
                while True:
                    ok, frame = capture.read()
                    if not ok:
                        break
                    landmarks = extractor.extract(frame) or {}
                    side = analyzed_side if analyzed_side in {"left", "right"} else None
                    if exercise_type is not ExerciseType.pinch:
                        self._draw_pose(frame, landmarks, width, height)
                    value = self._draw_measurement(
                        frame, landmarks, exercise_type, side, width, height
                    )
                    counter.update(value)
                    self._draw_panel(frame, exercise_type, value, counter)
                    writer.write(frame)
        except Exception as error:
            raise AnnotatedVideoError(
                "Não foi possível renderizar as anotações do vídeo."
            ) from error
        finally:
            capture.release()
            writer.release()

    def _draw_measurement(
        self,
        frame,
        landmarks: dict[str, Landmark],
        exercise_type: ExerciseType,
        side: Optional[str],
        width: int,
        height: int,
    ) -> Optional[float]:
        if exercise_type is ExerciseType.pinch:
            names = ["wrist", "thumb_tip", "index_tip"]
            if not all(name in landmarks for name in names):
                return None
            self._draw_connections(frame, landmarks, names, width, height)
            return euclidean_distance(landmarks["thumb_tip"], landmarks["index_tip"])

        selected = side or self._visible_side(landmarks, exercise_type)
        if selected is None:
            return None
        names = (
            [f"{selected}_shoulder", f"{selected}_elbow", f"{selected}_wrist"]
            if exercise_type is ExerciseType.elbow_flexion
            else [f"{selected}_hip", f"{selected}_knee", f"{selected}_ankle"]
        )
        if not all(name in landmarks for name in names):
            return None
        points = [landmarks[name] for name in names]
        if min(point.visibility for point in points) < 0.6:
            return None
        self._draw_connections(frame, landmarks, names, width, height)
        try:
            return joint_angle_degrees(points[0], points[1], points[2])
        except ValueError:
            return None

    @staticmethod
    def _visible_side(
        landmarks: dict[str, Landmark], exercise_type: ExerciseType
    ) -> Optional[str]:
        middle = "elbow" if exercise_type is ExerciseType.elbow_flexion else "knee"
        scores = {
            side: landmarks.get(f"{side}_{middle}").visibility
            if landmarks.get(f"{side}_{middle}") is not None
            else 0.0
            for side in ("left", "right")
        }
        selected = max(scores, key=scores.get)
        return selected if scores[selected] >= 0.6 else None

    @staticmethod
    def _draw_connections(frame, landmarks, names, width: int, height: int) -> None:
        points = [
            (int(landmarks[name].x * width), int(landmarks[name].y * height))
            for name in names
        ]
        for start, end in zip(points, points[1:]):
            cv2.line(frame, start, end, (33, 210, 168), 5, cv2.LINE_AA)
        for point in points:
            cv2.circle(frame, point, 8, (255, 255, 255), -1, cv2.LINE_AA)
            cv2.circle(frame, point, 8, (20, 92, 99), 3, cv2.LINE_AA)

    @staticmethod
    def _draw_pose(frame, landmarks, width: int, height: int) -> None:
        connections = (
            ("left_shoulder", "right_shoulder"),
            ("left_shoulder", "left_elbow"),
            ("left_elbow", "left_wrist"),
            ("right_shoulder", "right_elbow"),
            ("right_elbow", "right_wrist"),
            ("left_shoulder", "left_hip"),
            ("right_shoulder", "right_hip"),
            ("left_hip", "right_hip"),
            ("left_hip", "left_knee"),
            ("left_knee", "left_ankle"),
            ("right_hip", "right_knee"),
            ("right_knee", "right_ankle"),
        )
        visible_names = {
            name
            for connection in connections
            for name in connection
            if name in landmarks and landmarks[name].visibility >= 0.45
        }
        points = {
            name: (
                int(landmarks[name].x * width),
                int(landmarks[name].y * height),
            )
            for name in visible_names
        }
        for start, end in connections:
            if start in points and end in points:
                cv2.line(
                    frame, points[start], points[end], (255, 180, 52), 3,
                    cv2.LINE_AA,
                )
        for point in points.values():
            cv2.circle(frame, point, 6, (255, 255, 255), -1, cv2.LINE_AA)
            cv2.circle(frame, point, 6, (255, 126, 31), 2, cv2.LINE_AA)

    @staticmethod
    def _draw_panel(frame, exercise_type, value, counter: "_LiveCounter") -> None:
        height, width = frame.shape[:2]
        overlay = frame.copy()
        cv2.rectangle(overlay, (0, 0), (width, 126), (12, 35, 38), -1)
        cv2.rectangle(
            overlay, (0, max(0, height - 40)), (width, height), (12, 35, 38), -1
        )
        cv2.addWeighted(overlay, 0.82, frame, 0.18, 0, frame)
        label = "Distancia normalizada" if exercise_type is ExerciseType.pinch else "Angulo"
        formatted = "--" if value is None else (
            f"{value:.3f}" if exercise_type is ExerciseType.pinch else f"{value:.1f} graus"
        )
        cv2.putText(
            frame, f"{label}: {formatted}", (18, 36), cv2.FONT_HERSHEY_SIMPLEX,
            0.72, (255, 255, 255), 2, cv2.LINE_AA
        )
        cv2.putText(
            frame, f"Repeticoes: {counter.repetitions}", (18, 74), cv2.FONT_HERSHEY_SIMPLEX,
            0.78, (71, 231, 190), 2, cv2.LINE_AA
        )
        status = counter.status(value)
        status_color = (92, 224, 255) if value is None else (255, 255, 255)
        cv2.putText(
            frame, f"Estado: {status}", (18, 108), cv2.FONT_HERSHEY_SIMPLEX,
            0.62, status_color, 2, cv2.LINE_AA
        )
        cv2.putText(
            frame, "Analise experimental - requer revisao profissional",
            (14, height - 14), cv2.FONT_HERSHEY_SIMPLEX, 0.48,
            (255, 255, 255), 1, cv2.LINE_AA
        )


class _LiveCounter:
    def __init__(self, exercise_type: ExerciseType) -> None:
        self.exercise_type = exercise_type
        self.state = "waiting_start"
        self.repetitions = 0

    def update(self, value: Optional[float]) -> None:
        if value is None:
            return
        start, change = (
            (0.10, 0.05)
            if self.exercise_type is ExerciseType.pinch
            else (160.0, 100.0)
            if self.exercise_type is ExerciseType.squat
            else (160.0, 90.0)
        )
        if self.state == "waiting_start" and value >= start:
            self.state = "started"
        elif self.state == "started" and value <= change:
            self.state = "changed"
        elif self.state == "changed" and value >= start:
            self.repetitions += 1
            self.state = "started"

    def status(self, value: Optional[float]) -> str:
        if value is None:
            return (
                "mao nao detectada"
                if self.exercise_type is ExerciseType.pinch
                else "pose nao detectada"
            )
        return {
            "waiting_start": "aguardando posicao inicial",
            "started": "movimento iniciado",
            "changed": "retornando para completar",
        }.get(self.state, "analisando")
