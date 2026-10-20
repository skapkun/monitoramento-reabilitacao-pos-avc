from __future__ import annotations

import base64
from pathlib import Path
from typing import Iterable

import cv2

from app.schemas.analysis import AnalysisEvidence


class EvidenceService:
    def __init__(
        self,
        maximum_items: int = 4,
        maximum_width: int = 640,
        maximum_bytes: int = 90_000,
    ) -> None:
        self.maximum_items = maximum_items
        self.maximum_width = maximum_width
        self.maximum_bytes = maximum_bytes

    def capture(
        self, video_path: Path, movement_events: Iterable[dict]
    ) -> list[AnalysisEvidence]:
        all_events = list(movement_events)
        prioritized = sorted(
            enumerate(all_events),
            key=lambda item: (
                0
                if item[1].get("type") == "best_repetition"
                else 1
                if "possible_" in str(item[1].get("type", ""))
                else 2,
                item[0],
            ),
        )
        events = prioritized[: self.maximum_items]
        capture = cv2.VideoCapture(str(video_path))
        if not capture.isOpened():
            return []
        if not events:
            fps = capture.get(cv2.CAP_PROP_FPS)
            frame_count = capture.get(cv2.CAP_PROP_FRAME_COUNT)
            duration = frame_count / fps if fps and fps > 0 else 0.0
            events = [
                (
                    0,
                    {
                        "type": "analysis_context",
                        "title": "Enquadramento usado na análise",
                        "start_seconds": max(0.0, duration / 2),
                    },
                )
            ]
        evidence: list[AnalysisEvidence] = []
        try:
            for evidence_index, (_, event) in enumerate(events):
                seconds = max(0.0, float(event.get("start_seconds", 0) or 0))
                capture.set(cv2.CAP_PROP_POS_MSEC, seconds * 1000)
                ok, frame = capture.read()
                if not ok:
                    continue
                encoded = self._encode(frame)
                if encoded is None:
                    continue
                evidence.append(
                    AnalysisEvidence(
                        event_index=evidence_index,
                        event_type=str(event.get("type", "information"))[:80],
                        title=str(event.get("title", "Momento da análise"))[:160],
                        timestamp_seconds=seconds,
                        image_base64=base64.b64encode(encoded).decode("ascii"),
                    )
                )
        finally:
            capture.release()
        return evidence

    def _encode(self, frame) -> bytes | None:
        height, width = frame.shape[:2]
        if width > self.maximum_width:
            scale = self.maximum_width / width
            frame = cv2.resize(
                frame,
                (self.maximum_width, max(1, round(height * scale))),
                interpolation=cv2.INTER_AREA,
            )
        for quality in (72, 62, 52, 42, 32):
            ok, encoded = cv2.imencode(
                ".jpg", frame, [cv2.IMWRITE_JPEG_QUALITY, quality]
            )
            if ok and len(encoded) <= self.maximum_bytes:
                return encoded.tobytes()
        return None
