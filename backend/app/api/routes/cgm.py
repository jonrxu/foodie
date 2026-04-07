from datetime import UTC, date, datetime, timedelta

from fastapi import APIRouter, Depends, Query

from app.api.dependencies import get_current_user_id
from app.schemas.cgm import GlucoseReadingsResponse, WeeklyGlucoseSummaryResponse
from app.services.cgm_service import CGMService
from app.services.container import get_cgm_service

router = APIRouter(prefix="/cgm", tags=["cgm"])


@router.get("/summary/weekly", response_model=WeeklyGlucoseSummaryResponse)
async def get_weekly_glucose_summary(
    anchor_date: date | None = Query(default=None),
    user_id: str = Depends(get_current_user_id),
    service: CGMService = Depends(get_cgm_service),
) -> WeeklyGlucoseSummaryResponse:
    return service.fetch_weekly_summary(user_id=user_id, anchor_date=anchor_date)


@router.get("/readings", response_model=GlucoseReadingsResponse)
async def get_glucose_readings(
    start: datetime | None = Query(default=None),
    end: datetime | None = Query(default=None),
    user_id: str = Depends(get_current_user_id),
    service: CGMService = Depends(get_cgm_service),
) -> GlucoseReadingsResponse:
    window_end = _to_utc(end) if end else datetime.now(UTC)
    window_start = _to_utc(start) if start else window_end - timedelta(days=7)
    return service.fetch_readings(user_id=user_id, start=window_start, end=window_end)


def _to_utc(value: datetime) -> datetime:
    if value.tzinfo is None:
        return value.replace(tzinfo=UTC)
    return value.astimezone(UTC)
