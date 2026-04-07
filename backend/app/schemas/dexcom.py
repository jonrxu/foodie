from datetime import datetime
from typing import Literal

from pydantic import BaseModel, HttpUrl

ConnectionStatus = Literal["disconnected", "pending", "connected", "error"]


class DexcomConnectStartResponse(BaseModel):
    authorization_url: HttpUrl
    connection_status: ConnectionStatus


class DexcomConnectionStatusResponse(BaseModel):
    provider: Literal["dexcom"] = "dexcom"
    status: ConnectionStatus
    connected_at: datetime | None = None
    last_sync_at: datetime | None = None
    error_message: str | None = None


class DexcomCallbackResponse(BaseModel):
    provider: Literal["dexcom"] = "dexcom"
    status: ConnectionStatus
    redirect_to: str


class DexcomSyncResponse(BaseModel):
    status: Literal["queued", "completed"]
    synced_at: datetime


class DexcomDisconnectResponse(BaseModel):
    provider: Literal["dexcom"] = "dexcom"
    status: Literal["disconnected"]
