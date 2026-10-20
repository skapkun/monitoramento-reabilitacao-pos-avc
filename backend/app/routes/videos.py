from __future__ import annotations

from datetime import datetime
from pathlib import Path
from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, File, Form, HTTPException, Response, UploadFile, status

from app.config import settings
from app.routes.analysis import ALLOWED_VIDEO_EXTENSIONS, ALLOWED_VIDEO_TYPES
from app.schemas.analysis import ExerciseType
from app.security.firebase_auth import AuthenticatedUser, require_authenticated_user
from app.services.annotated_video_service import (
    AnnotatedVideoError,
    AnnotatedVideoService,
)
from app.services.video_storage_service import (
    VideoAccessDeniedError,
    VideoNotFoundError,
    VideoStorageService,
)


router = APIRouter(prefix="/videos", tags=["videos"])
video_storage_service = VideoStorageService(
    storage_dir=Path(settings.video_storage_dir),
    database_path=Path(settings.video_database_path),
    key_path=Path(settings.video_key_path),
    encryption_key=settings.video_encryption_key,
    retention_days=settings.video_retention_days,
)
annotated_video_service = AnnotatedVideoService()


@router.post("", status_code=status.HTTP_201_CREATED)
async def upload_video(
    video_file: UploadFile = File(...),
    session_id: UUID = Form(...),
    therapist_id: str = Form(..., min_length=1, max_length=128),
    consent_at: datetime = Form(...),
    current_user: AuthenticatedUser = Depends(require_authenticated_user),
) -> dict:
    extension = Path(video_file.filename or "").suffix.lower()
    if video_file.content_type not in ALLOWED_VIDEO_TYPES or extension not in ALLOWED_VIDEO_EXTENSIONS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Envie um vídeo MP4, MOV ou WebM válido.",
        )
    content = await video_file.read(settings.max_upload_bytes + 1)
    await video_file.close()
    if not content:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="O arquivo de vídeo está vazio.",
        )
    if len(content) > settings.max_upload_bytes:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail="O vídeo ultrapassa o limite configurado.",
        )
    stored = video_storage_service.store(
        session_id=session_id,
        patient_id=current_user.uid,
        therapist_id=therapist_id,
        content_type=video_file.content_type,
        original_filename=video_file.filename or f"{session_id}{extension}",
        consent_at=consent_at,
        content=content,
    )
    return {
        "status": "success",
        "data": {
            "session_id": stored.session_id,
            "storage_path": f"fastapi://videos/{stored.session_id}",
            "shared_at": stored.created_at.isoformat(),
            "consent_at": stored.consent_at.isoformat(),
            "retention_until": stored.expires_at.isoformat(),
            "consent_version": "video-sharing-v2-local-encrypted",
            "byte_size": stored.byte_size,
        },
        "message": "Vídeo criptografado e armazenado de forma privada.",
    }


@router.get("/{session_id}")
def download_video(
    session_id: UUID,
    current_user: AuthenticatedUser = Depends(require_authenticated_user),
) -> Response:
    try:
        metadata, content = video_storage_service.retrieve(session_id, current_user.uid)
    except VideoAccessDeniedError as error:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Vídeo não encontrado.") from error
    except VideoNotFoundError as error:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Vídeo não encontrado.") from error
    return Response(
        content=content,
        media_type=metadata.content_type,
        headers={
            "Content-Disposition": f'inline; filename="{metadata.original_filename}"',
            "Cache-Control": "private, no-store",
            "X-Content-Type-Options": "nosniff",
        },
    )


@router.get("/{session_id}/annotated")
def download_annotated_video(
    session_id: UUID,
    exercise_type: ExerciseType,
    analyzed_side: Optional[str] = None,
    current_user: AuthenticatedUser = Depends(require_authenticated_user),
) -> Response:
    try:
        _metadata, content = video_storage_service.retrieve(
            session_id, current_user.uid
        )
        annotated = annotated_video_service.render(
            content,
            exercise_type=exercise_type,
            analyzed_side=(
                analyzed_side if analyzed_side in {"left", "right"} else None
            ),
        )
    except VideoAccessDeniedError as error:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Vídeo não encontrado.",
        ) from error
    except VideoNotFoundError as error:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Vídeo não encontrado.",
        ) from error
    except AnnotatedVideoError as error:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=str(error),
        ) from error
    return Response(
        content=annotated,
        media_type="video/mp4",
        headers={
            "Content-Disposition": (
                f'inline; filename="movere-{session_id}-anotado.mp4"'
            ),
            "Cache-Control": "private, no-store",
            "X-Content-Type-Options": "nosniff",
        },
    )


@router.delete("/{session_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_video(
    session_id: UUID,
    current_user: AuthenticatedUser = Depends(require_authenticated_user),
) -> Response:
    try:
        video_storage_service.delete(session_id, current_user.uid)
    except VideoAccessDeniedError as error:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Vídeo não encontrado.") from error
    return Response(status_code=status.HTTP_204_NO_CONTENT)
