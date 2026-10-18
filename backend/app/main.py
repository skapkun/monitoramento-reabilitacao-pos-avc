import asyncio
from contextlib import asynccontextmanager, suppress

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.routes.analysis import router as analysis_router
from app.routes.health import router as health_router
from app.routes.reports import router as reports_router
from app.routes.videos import router as videos_router, video_storage_service


async def cleanup_expired_videos() -> None:
    while True:
        await asyncio.to_thread(video_storage_service.cleanup_expired)
        await asyncio.sleep(settings.video_cleanup_interval_seconds)


@asynccontextmanager
async def lifespan(_: FastAPI):
    cleanup_task = asyncio.create_task(cleanup_expired_videos())
    try:
        yield
    finally:
        cleanup_task.cancel()
        with suppress(asyncio.CancelledError):
            await cleanup_task


def create_app() -> FastAPI:
    app = FastAPI(
        title=settings.app_name,
        version=settings.app_version,
        description=(
            "API do protótipo acadêmico Movere. Não realiza diagnóstico "
            "nem substitui avaliação profissional."
        ),
        lifespan=lifespan,
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
    app.include_router(videos_router)
    return app


app = create_app()
