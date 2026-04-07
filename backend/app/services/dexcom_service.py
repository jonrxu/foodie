from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from secrets import token_urlsafe
from urllib.parse import urlencode

import httpx

from app.api.errors import AppError
from app.config.settings import Settings
from app.persistence.dexcom_store import DexcomConnectionRecord, SQLiteDexcomConnectionStore
from app.schemas.dexcom import (
    DexcomConnectionStatusResponse,
    DexcomConnectStartResponse,
    DexcomDisconnectResponse,
    DexcomSyncResponse,
)


@dataclass
class DexcomCallbackOutcome:
    status: str
    redirect_to: str


@dataclass
class DexcomTokenPayload:
    access_token: str
    refresh_token: str | None
    token_type: str
    expires_in: int | None = None


class DexcomService:
    STATE_TTL_MINUTES = 10
    TOKEN_EXPIRY_SAFETY_BUFFER = timedelta(minutes=5)

    def __init__(self, settings: Settings, store: SQLiteDexcomConnectionStore) -> None:
        self.settings = settings
        self.store = store

    def start_connection(self, user_id: str) -> DexcomConnectStartResponse:
        record = self.store.get(user_id)
        state = token_urlsafe(24)
        now = datetime.now(UTC)

        record.status = "pending"
        record.error_message = None
        record.pending_state = state
        record.pending_started_at = now
        self.store.save(user_id, record)

        query = urlencode(
            {
                "client_id": self.settings.dexcom_client_id,
                "redirect_uri": str(self.settings.dexcom_redirect_uri),
                "response_type": "code",
                "scope": self.settings.dexcom_scope,
                "state": state,
            }
        )
        authorization_url = f"{self.settings.dexcom_authorize_base}?{query}"

        return DexcomConnectStartResponse(
            authorization_url=authorization_url,
            connection_status="pending",
        )

    def get_status(self, user_id: str) -> DexcomConnectionStatusResponse:
        record = self.store.get(user_id)
        return DexcomConnectionStatusResponse(
            status=record.status,  # type: ignore[arg-type]
            connected_at=record.connected_at,
            last_sync_at=record.last_sync_at,
            error_message=record.error_message,
        )

    def get_record(self, user_id: str) -> DexcomConnectionRecord:
        return self.store.get(user_id)

    def complete_callback(self, state: str, code: str | None, error: str | None) -> DexcomCallbackOutcome:
        user_id = self.store.resolve_user_by_state(state)
        if not user_id:
            raise AppError(
                code="dexcom_invalid_state",
                message="Dexcom OAuth state is invalid or expired",
                status_code=400,
            )

        record = self.store.get(user_id)
        if record.pending_state != state or not record.pending_started_at:
            raise AppError(
                code="dexcom_invalid_state",
                message="Dexcom OAuth state does not match pending authorization",
                status_code=400,
            )

        if datetime.now(UTC) - record.pending_started_at > timedelta(minutes=self.STATE_TTL_MINUTES):
            record.status = "error"
            record.error_message = "Authorization window expired. Please reconnect Dexcom."
            self.store.remove_state(state)
            self.store.save(user_id, record)
            raise AppError(
                code="dexcom_state_expired",
                message=record.error_message,
                status_code=400,
            )

        if error:
            record.status = "error"
            record.error_message = f"Dexcom authorization failed: {error}"
            record.pending_state = None
            record.pending_started_at = None
            self.store.remove_state(state)
            self.store.save(user_id, record)
            return DexcomCallbackOutcome(
                status="error",
                redirect_to=f"{self.settings.app_deep_link_base}dexcom-connected?status=error",
            )

        if not code:
            raise AppError(
                code="dexcom_missing_code",
                message="Dexcom callback did not include an authorization code",
                status_code=400,
            )

        token_payload = self._exchange_authorization_code(code)
        now = datetime.now(UTC)
        record.status = "connected"
        record.connected_at = now
        record.last_sync_at = None
        record.error_message = None
        record.pending_state = None
        record.pending_started_at = None
        record.access_token = token_payload.access_token
        record.refresh_token = token_payload.refresh_token
        record.token_type = token_payload.token_type
        record.expires_at = (
            now + timedelta(seconds=token_payload.expires_in)
            if token_payload.expires_in is not None
            else None
        )
        self.store.remove_state(state)
        self.store.save(user_id, record)

        return DexcomCallbackOutcome(
            status="connected",
            redirect_to=f"{self.settings.app_deep_link_base}dexcom-connected?status=connected",
        )

    def disconnect(self, user_id: str) -> DexcomDisconnectResponse:
        record = self.store.get(user_id)
        if record.pending_state:
            self.store.remove_state(record.pending_state)

        record.status = "disconnected"
        record.connected_at = None
        record.last_sync_at = None
        record.error_message = None
        record.pending_state = None
        record.pending_started_at = None
        record.access_token = None
        record.refresh_token = None
        record.token_type = None
        record.expires_at = None
        self.store.save(user_id, record)
        return DexcomDisconnectResponse(status="disconnected")

    def trigger_sync(self, user_id: str) -> DexcomSyncResponse:
        record = self.get_authenticated_record(user_id)
        now = datetime.now(UTC)
        record.last_sync_at = now
        self.store.save(user_id, record)
        return DexcomSyncResponse(status="queued", synced_at=now)

    def mark_connected_for_demo(self, user_id: str) -> DexcomConnectionStatusResponse:
        """Temporary helper route for iOS prototype wiring.

        TODO: remove after callback flow is consumed by the iOS app.
        """
        record = self.store.get(user_id)
        now = datetime.now(UTC)
        record.status = "connected"
        record.connected_at = now
        record.last_sync_at = now
        record.error_message = None
        record.access_token = f"mock-access-{token_urlsafe(16)}"
        record.refresh_token = f"mock-refresh-{token_urlsafe(16)}"
        record.token_type = "Bearer"
        record.expires_at = now + timedelta(hours=2)
        self.store.save(user_id, record)
        return self.get_status(user_id)

    def get_authenticated_record(self, user_id: str) -> DexcomConnectionRecord:
        record = self.store.get(user_id)
        if record.status != "connected":
            raise AppError(
                code="dexcom_not_connected",
                message="Dexcom is not connected for this user",
                status_code=409,
            )

        if not record.access_token:
            raise AppError(
                code="dexcom_missing_tokens",
                message="Dexcom is connected but missing tokens. Please reconnect.",
                status_code=409,
            )

        refreshed = self._refresh_access_token_if_needed(user_id, record)
        self.store.save(user_id, refreshed)
        return refreshed

    def _exchange_authorization_code(self, code: str) -> DexcomTokenPayload:
        if self.settings.dexcom_mock_oauth or self._has_placeholder_credentials():
            return DexcomTokenPayload(
                access_token=f"mock-access-{token_urlsafe(16)}",
                refresh_token=f"mock-refresh-{token_urlsafe(16)}",
                token_type="Bearer",
                expires_in=3600,
            )

        try:
            response = httpx.post(
                str(self.settings.dexcom_token_url),
                data={
                    "grant_type": "authorization_code",
                    "code": code,
                    "redirect_uri": str(self.settings.dexcom_redirect_uri),
                    "client_id": self.settings.dexcom_client_id,
                    "client_secret": self.settings.dexcom_client_secret,
                },
                timeout=10.0,
            )
            response.raise_for_status()
        except httpx.HTTPError as exc:
            raise AppError(
                code="dexcom_token_exchange_failed",
                message="Dexcom token exchange failed",
                status_code=502,
            ) from exc

        payload = response.json()
        access_token = payload.get("access_token")
        token_type = payload.get("token_type")
        if not access_token or not token_type:
            raise AppError(
                code="dexcom_invalid_token_response",
                message="Dexcom token exchange returned an invalid payload",
                status_code=502,
            )

        return DexcomTokenPayload(
            access_token=access_token,
            refresh_token=payload.get("refresh_token"),
            token_type=token_type,
            expires_in=payload.get("expires_in"),
        )

    def _refresh_access_token_if_needed(
        self,
        user_id: str,
        record: DexcomConnectionRecord,
    ) -> DexcomConnectionRecord:
        if not record.expires_at or record.expires_at > datetime.now(UTC) + self.TOKEN_EXPIRY_SAFETY_BUFFER:
            return record

        if not record.refresh_token:
            record.status = "error"
            record.error_message = "Dexcom session expired. Please reconnect Dexcom."
            self.store.save(user_id, record)
            raise AppError(
                code="dexcom_refresh_failed",
                message=record.error_message,
                status_code=409,
            )

        if self.settings.dexcom_mock_oauth or self._has_placeholder_credentials():
            record.access_token = f"mock-access-{token_urlsafe(16)}"
            record.refresh_token = f"mock-refresh-{token_urlsafe(16)}"
            record.token_type = "Bearer"
            record.expires_at = datetime.now(UTC) + timedelta(hours=1)
            return record

        try:
            response = httpx.post(
                str(self.settings.dexcom_token_url),
                data={
                    "grant_type": "refresh_token",
                    "refresh_token": record.refresh_token,
                    "client_id": self.settings.dexcom_client_id,
                    "client_secret": self.settings.dexcom_client_secret,
                },
                timeout=10.0,
            )
            response.raise_for_status()
        except httpx.HTTPError as exc:
            record.status = "error"
            record.error_message = "Dexcom token refresh failed. Please reconnect Dexcom."
            self.store.save(user_id, record)
            raise AppError(
                code="dexcom_refresh_failed",
                message=record.error_message,
                status_code=502,
            ) from exc

        payload = response.json()
        access_token = payload.get("access_token")
        token_type = payload.get("token_type")
        if not access_token or not token_type:
            record.status = "error"
            record.error_message = "Dexcom returned an invalid refresh response."
            self.store.save(user_id, record)
            raise AppError(
                code="dexcom_invalid_token_response",
                message=record.error_message,
                status_code=502,
            )

        record.access_token = access_token
        record.refresh_token = payload.get("refresh_token", record.refresh_token)
        record.token_type = token_type
        expires_in = payload.get("expires_in")
        record.expires_at = (
            datetime.now(UTC) + timedelta(seconds=expires_in)
            if expires_in is not None
            else record.expires_at
        )
        record.error_message = None
        return record

    def _has_placeholder_credentials(self) -> bool:
        return (
            self.settings.dexcom_client_id == "replace-me"
            or self.settings.dexcom_client_secret == "replace-me"
        )
