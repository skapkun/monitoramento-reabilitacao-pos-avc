from fastapi import APIRouter, Depends, Response

from app.schemas.report import LongitudinalReportRequest, SessionReportRequest
from app.security.firebase_auth import AuthenticatedUser, require_authenticated_user
from app.services.report_service import ReportService


router = APIRouter(prefix="/reports", tags=["reports"])
report_service = ReportService()


@router.post("/longitudinal.pdf", response_class=Response)
def create_longitudinal_report(
    payload: LongitudinalReportRequest,
    _current_user: AuthenticatedUser = Depends(require_authenticated_user),
) -> Response:
    content = report_service.longitudinal_pdf(payload)
    return Response(
        content=content,
        media_type="application/pdf",
        headers={"Content-Disposition": 'attachment; filename="movere-relatorio.pdf"'},
    )


@router.post("/session.pdf", response_class=Response)
def create_session_report(
    payload: SessionReportRequest,
    _current_user: AuthenticatedUser = Depends(require_authenticated_user),
) -> Response:
    content = report_service.session_pdf(payload)
    return Response(
        content=content,
        media_type="application/pdf",
        headers={"Content-Disposition": 'attachment; filename="movere-sessao.pdf"'},
    )
