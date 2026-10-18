from __future__ import annotations

import base64
import hashlib
import hmac
import json
import os
import sqlite3
from dataclasses import asdict, dataclass
from datetime import datetime, timedelta, timezone
from pathlib import Path
from threading import Lock
from uuid import UUID, uuid4

from cryptography.hazmat.primitives.ciphers.aead import AESGCM


@dataclass(frozen=True)
class StoredVideo:
    session_id: str
    patient_id: str
    therapist_id: str
    content_type: str
    original_filename: str
    created_at: datetime
    consent_at: datetime
    expires_at: datetime
    byte_size: int


class VideoNotFoundError(Exception):
    pass


class VideoAccessDeniedError(Exception):
    pass


class VideoStorageService:
    def __init__(
        self,
        storage_dir: Path,
        database_path: Path,
        key_path: Path,
        encryption_key: str = "",
        retention_days: int = 30,
    ) -> None:
        if retention_days < 1 or retention_days > 365:
            raise ValueError("A retenção deve estar entre 1 e 365 dias.")
        self.storage_dir = storage_dir
        self.database_path = database_path
        self.key_path = key_path
        self.retention_days = retention_days
        self._lock = Lock()
        self.storage_dir.mkdir(parents=True, exist_ok=True)
        self.database_path.parent.mkdir(parents=True, exist_ok=True)
        self._key = self._load_key(encryption_key)
        self._cipher = AESGCM(self._key)
        self._initialize_database()
        self.cleanup_expired()

    def store(
        self,
        session_id: UUID,
        patient_id: str,
        therapist_id: str,
        content_type: str,
        original_filename: str,
        consent_at: datetime,
        content: bytes,
    ) -> StoredVideo:
        if not content:
            raise ValueError("O vídeo está vazio.")
        created_at = datetime.now(timezone.utc)
        metadata = StoredVideo(
            session_id=str(session_id),
            patient_id=patient_id,
            therapist_id=therapist_id,
            content_type=content_type,
            original_filename=self._safe_filename(original_filename),
            created_at=created_at,
            consent_at=self._utc(consent_at),
            expires_at=created_at + timedelta(days=self.retention_days),
            byte_size=len(content),
        )
        session_hash = self._session_hash(session_id)
        storage_name = f"{uuid4().hex}.enc"
        storage_path = self.storage_dir / storage_name
        video_nonce = os.urandom(12)
        encrypted_video = self._cipher.encrypt(
            video_nonce, content, session_hash.encode("ascii")
        )
        temporary_path = storage_path.with_suffix(".tmp")
        temporary_path.write_bytes(video_nonce + encrypted_video)
        os.chmod(temporary_path, 0o600)
        temporary_path.replace(storage_path)
        metadata_nonce = os.urandom(12)
        metadata_payload = json.dumps(
            {
                **asdict(metadata),
                "created_at": metadata.created_at.isoformat(),
                "consent_at": metadata.consent_at.isoformat(),
                "expires_at": metadata.expires_at.isoformat(),
            },
            separators=(",", ":"),
        ).encode("utf-8")
        encrypted_metadata = self._cipher.encrypt(
            metadata_nonce,
            metadata_payload,
            session_hash.encode("ascii"),
        )
        try:
            with self._lock, self._connect() as connection:
                previous = connection.execute(
                    "SELECT storage_name FROM encrypted_videos WHERE session_hash = ?",
                    (session_hash,),
                ).fetchone()
                connection.execute(
                    """
                    INSERT INTO encrypted_videos (
                        session_hash, metadata_nonce, encrypted_metadata,
                        storage_name, expires_at, byte_size
                    ) VALUES (?, ?, ?, ?, ?, ?)
                    ON CONFLICT(session_hash) DO UPDATE SET
                        metadata_nonce = excluded.metadata_nonce,
                        encrypted_metadata = excluded.encrypted_metadata,
                        storage_name = excluded.storage_name,
                        expires_at = excluded.expires_at,
                        byte_size = excluded.byte_size
                    """,
                    (
                        session_hash,
                        metadata_nonce,
                        encrypted_metadata,
                        storage_name,
                        metadata.expires_at.isoformat(),
                        metadata.byte_size,
                    ),
                )
                connection.commit()
        except Exception:
            storage_path.unlink(missing_ok=True)
            raise
        if previous and previous[0] != storage_name:
            (self.storage_dir / previous[0]).unlink(missing_ok=True)
        return metadata

    def retrieve(self, session_id: UUID, user_id: str) -> tuple[StoredVideo, bytes]:
        record = self._record(session_id)
        if record is None:
            raise VideoNotFoundError
        metadata, storage_name = record
        if user_id not in {metadata.patient_id, metadata.therapist_id}:
            raise VideoAccessDeniedError
        if metadata.expires_at <= datetime.now(timezone.utc):
            self.delete_expired(session_id)
            raise VideoNotFoundError
        path = self.storage_dir / storage_name
        if not path.is_file():
            self._delete_metadata(session_id)
            raise VideoNotFoundError
        payload = path.read_bytes()
        if len(payload) <= 12:
            raise VideoNotFoundError
        try:
            content = self._cipher.decrypt(
                payload[:12],
                payload[12:],
                self._session_hash(session_id).encode("ascii"),
            )
        except Exception as error:
            raise VideoNotFoundError from error
        return metadata, content

    def delete(self, session_id: UUID, user_id: str) -> None:
        record = self._record(session_id)
        if record is None:
            return
        metadata, storage_name = record
        if user_id != metadata.patient_id:
            raise VideoAccessDeniedError
        (self.storage_dir / storage_name).unlink(missing_ok=True)
        self._delete_metadata(session_id)

    def delete_expired(self, session_id: UUID) -> None:
        record = self._record(session_id)
        if record is None:
            return
        _, storage_name = record
        (self.storage_dir / storage_name).unlink(missing_ok=True)
        self._delete_metadata(session_id)

    def cleanup_expired(self) -> int:
        now = datetime.now(timezone.utc).isoformat()
        with self._lock, self._connect() as connection:
            rows = connection.execute(
                """
                SELECT session_hash, storage_name
                FROM encrypted_videos WHERE expires_at <= ?
                """,
                (now,),
            ).fetchall()
            connection.executemany(
                "DELETE FROM encrypted_videos WHERE session_hash = ?",
                [(row[0],) for row in rows],
            )
            connection.commit()
        for _, storage_name in rows:
            (self.storage_dir / storage_name).unlink(missing_ok=True)
        return len(rows)

    def _record(self, session_id: UUID) -> tuple[StoredVideo, str] | None:
        session_hash = self._session_hash(session_id)
        with self._lock, self._connect() as connection:
            row = connection.execute(
                """
                SELECT metadata_nonce, encrypted_metadata, storage_name
                FROM encrypted_videos WHERE session_hash = ?
                """,
                (session_hash,),
            ).fetchone()
        if row is None:
            return None
        try:
            plaintext = self._cipher.decrypt(
                row[0], row[1], session_hash.encode("ascii")
            )
            data = json.loads(plaintext.decode("utf-8"))
            metadata = StoredVideo(
                session_id=data["session_id"],
                patient_id=data["patient_id"],
                therapist_id=data["therapist_id"],
                content_type=data["content_type"],
                original_filename=data["original_filename"],
                created_at=datetime.fromisoformat(data["created_at"]),
                consent_at=datetime.fromisoformat(data["consent_at"]),
                expires_at=datetime.fromisoformat(data["expires_at"]),
                byte_size=int(data["byte_size"]),
            )
        except Exception as error:
            raise VideoNotFoundError from error
        return metadata, row[2]

    def _initialize_database(self) -> None:
        with self._connect() as connection:
            connection.execute(
                """
                CREATE TABLE IF NOT EXISTS encrypted_videos (
                    session_hash TEXT PRIMARY KEY,
                    metadata_nonce BLOB NOT NULL,
                    encrypted_metadata BLOB NOT NULL,
                    storage_name TEXT NOT NULL UNIQUE,
                    expires_at TEXT NOT NULL,
                    byte_size INTEGER NOT NULL
                )
                """
            )
            connection.commit()

    def _connect(self) -> sqlite3.Connection:
        return sqlite3.connect(self.database_path, timeout=10)

    def _delete_metadata(self, session_id: UUID) -> None:
        session_hash = self._session_hash(session_id)
        with self._lock, self._connect() as connection:
            connection.execute(
                "DELETE FROM encrypted_videos WHERE session_hash = ?",
                (session_hash,),
            )
            connection.commit()

    def _session_hash(self, session_id: UUID) -> str:
        return hmac.new(
            self._key,
            str(session_id).encode("utf-8"),
            hashlib.sha256,
        ).hexdigest()

    def _load_key(self, configured: str) -> bytes:
        if configured:
            try:
                key = base64.urlsafe_b64decode(configured.encode("ascii"))
            except Exception as error:
                raise ValueError("VIDEO_ENCRYPTION_KEY não é válida.") from error
            if len(key) != 32:
                raise ValueError("VIDEO_ENCRYPTION_KEY deve representar 32 bytes.")
            return key
        self.key_path.parent.mkdir(parents=True, exist_ok=True)
        if self.key_path.exists():
            key = self.key_path.read_bytes()
            if len(key) != 32:
                raise ValueError("O arquivo da chave de vídeo é inválido.")
            return key
        key = AESGCM.generate_key(bit_length=256)
        descriptor = os.open(
            self.key_path,
            os.O_WRONLY | os.O_CREAT | os.O_EXCL,
            0o600,
        )
        with os.fdopen(descriptor, "wb") as key_file:
            key_file.write(key)
        return key

    @staticmethod
    def _safe_filename(value: str) -> str:
        name = Path(value).name.replace('"', "").replace("\r", "").replace("\n", "")
        return name[:180] or "video.mp4"

    @staticmethod
    def _utc(value: datetime) -> datetime:
        if value.tzinfo is None:
            return value.replace(tzinfo=timezone.utc)
        return value.astimezone(timezone.utc)
