from fastapi import APIRouter, Depends, Query
from fastapi.responses import RedirectResponse

from app.api.dependencies import get_current_user_id
from app.schemas.dexcom import (
    DexcomConnectionStatusResponse,
    DexcomConnectStartResponse,
    DexcomDisconnectResponse,
    DexcomSyncResponse,
)
from app.services.cgm_service import CGMService
from app.services.container import get_cgm_service, get_dexcom_service
from app.services.dexcom_service import DexcomService

router = APIRouter(prefix="/dexcom", tags=["dexcom"])


@router.post("/connect/start", response_model=DexcomConnectStartResponse)
async def start_dexcom_connection(
    user_id: str = Depends(get_current_user_id),
    service: DexcomService = Depends(get_dexcom_service),
) -> DexcomConnectStartResponse:
    return service.start_connection(user_id=user_id)


@router.get("/connect/callback")
async def dexcom_connect_callback(
    state: str = Query(...),
    code: str | None = Query(default=None),
    error: str | None = Query(default=None),
    service: DexcomService = Depends(get_dexcom_service),
) -> RedirectResponse:
    outcome = service.complete_callback(state=state, code=code, error=error)
    return RedirectResponse(url=outcome.redirect_to, status_code=302)


@router.get("/connect/status", response_model=DexcomConnectionStatusResponse)
async def get_dexcom_connection_status(
    user_id: str = Depends(get_current_user_id),
    service: DexcomService = Depends(get_dexcom_service),
) -> DexcomConnectionStatusResponse:
    return service.get_status(user_id=user_id)


@router.post("/disconnect", response_model=DexcomDisconnectResponse)
async def disconnect_dexcom(
    user_id: str = Depends(get_current_user_id),
    service: DexcomService = Depends(get_dexcom_service),
) -> DexcomDisconnectResponse:
    return service.disconnect(user_id=user_id)


@router.post("/sync", response_model=DexcomSyncResponse)
async def trigger_dexcom_sync(
    user_id: str = Depends(get_current_user_id),
    service: CGMService = Depends(get_cgm_service),
) -> DexcomSyncResponse:
    result = service.sync_recent_glucose(user_id=user_id)
    return DexcomSyncResponse(status="completed", synced_at=result.synced_at)


@router.post("/connect/mock-complete", response_model=DexcomConnectionStatusResponse)
async def mock_complete_connection(
    user_id: str = Depends(get_current_user_id),
    service: DexcomService = Depends(get_dexcom_service),
) -> DexcomConnectionStatusResponse:
    return service.mark_connected_for_demo(user_id=user_id)
