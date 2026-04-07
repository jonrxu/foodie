from fastapi import APIRouter, Depends

from app.api.dependencies import settings_dependency
from app.config.settings import Settings

router = APIRouter(tags=["health"])


@router.get("/healthz")
async def healthz() -> dict[str, str]:
    return {"status": "ok"}


@router.get("/readyz")
async def readyz(settings: Settings = Depends(settings_dependency)) -> dict[str, str]:
    # TODO: add DB/Redis readiness checks when persistence layer lands.
    return {"status": "ready", "env": settings.app_env}
