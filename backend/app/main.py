from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.routes.analysis import router as analysis_router
from app.routes.health import router as health_router
from app.routes.reports import router as reports_router


def create_app() -> FastAPI:
    app = FastAPI(
        title=settings.app_name,
        version=settings.app_version,
        description=(
            "API do protótipo acadêmico Movere. Não realiza diagnóstico "
            "nem substitui avaliação profissional."
        ),
    )
    app.add_middleware(
        CORSMiddleware,
        allow_origins=list(settings.allowed_origins),
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    app.include_router(health_router)
    app.include_router(analysis_router)
    app.include_router(reports_router)
    return app


app = create_app()
