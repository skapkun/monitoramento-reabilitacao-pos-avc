import tempfile
from pathlib import Path
from typing import Optional
from uuid import UUID

from fastapi import (
    APIRouter,
    BackgroundTasks,
    Depends,
    File,
    Form,
    HTTPException,
    UploadFile,
    status,
)

from app.config import settings
from app.schemas.analysis import ApiResponse, ExerciseType
from app.security.firebase_auth import AuthenticatedUser, require_authenticated_user
from app.services.analysis_service import AnalysisService


router = APIRouter(prefix="/analysis", tags=["analysis"])

ALLOWED_VIDEO_TYPES = {"video/mp4", "video/quicktime", "video/webm"}
ALLOWED_VIDEO_EXTENSIONS = {".mp4", ".mov", ".webm"}
analysis_service = AnalysisService(mode=settings.analysis_mode)
analysis_owners: dict[UUID, str] = {}


async def save_validated_video(video_file: UploadFile) -> Path:
    extension = Path(video_file.filename or "").suffix.lower()
    if video_file.content_type not in ALLOWED_VIDEO_TYPES or extension not in ALLOWED_VIDEO_EXTENSIONS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Envie um vídeo MP4, MOV ou WebM válido.",
        )

    temporary_directory = settings.analysis_temp_dir or None
    temporary = tempfile.NamedTemporaryFile(
        mode="wb",
        suffix=extension,
        prefix="movere-analysis-",
        dir=temporary_directory,
        delete=False,
    )
    path = Path(temporary.name)
    total_size = 0
    try:
        with temporary:
            while chunk := await video_file.read(1024 * 1024):
                total_size += len(chunk)
                if total_size > settings.max_upload_bytes:
                    raise HTTPException(
                        status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                        detail="O vídeo ultrapassa o limite configurado.",
                    )
                temporary.write(chunk)
        if total_size == 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="O arquivo de vídeo está vazio.",
            )
        return path
    except Exception:
        path.unlink(missing_ok=True)
        raise


@router.post("", response_model=ApiResponse, status_code=status.HTTP_202_ACCEPTED)
async def create_analysis(
    background_tasks: BackgroundTasks,
    video_file: UploadFile = File(...),
    exercise_type: ExerciseType = Form(...),
    session_id: UUID = Form(...),
    affected_side: Optional[str] = Form(default=None),
    detection_start_threshold: Optional[float] = Form(default=None),
    detection_change_threshold: Optional[float] = Form(default=None),
    current_user: AuthenticatedUser = Depends(require_authenticated_user),
) -> ApiResponse:
    temporary_path = None
    try:
        temporary_path = await save_validated_video(video_file)
        try:
            thresholds = analysis_service.validate_calibration(
                exercise_type,
                detection_start_threshold,
                detection_change_threshold,
            )
        except ValueError as error:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=str(error),
            ) from error
        result = analysis_service.create(session_id, exercise_type)
        analysis_owners[result.analysis_id] = current_user.uid
        normalized_side = affected_side if affected_side in {"left", "right"} else None
        background_tasks.add_task(
            analysis_service.process,
            result.analysis_id,
            temporary_path,
            normalized_side,
            thresholds,
        )
        temporary_path = None
        return ApiResponse(
            data=result,
            message=(
                "Solicitação de análise simulada aceita."
                if result.simulated
                else "Solicitação de análise real aceita."
            ),
        )
    finally:
        if temporary_path is not None:
            temporary_path.unlink(missing_ok=True)
        await video_file.close()


@router.get("/{analysis_id}", response_model=ApiResponse)
def get_analysis(
    analysis_id: UUID,
    current_user: AuthenticatedUser = Depends(require_authenticated_user),
) -> ApiResponse:
    result = analysis_service.get(analysis_id)
    if result is None or analysis_owners.get(analysis_id) != current_user.uid:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Análise não encontrada.",
        )
    return ApiResponse(
        data=result,
        message="Estado da análise recuperado.",
    )
