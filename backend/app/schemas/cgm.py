from datetime import datetime

from pydantic import BaseModel


class GlucoseReadingResponse(BaseModel):
    id: str
    timestamp: datetime
    valueMgdl: int
    source: str
    trend: str | None = None


class GlucoseReadingsResponse(BaseModel):
    readings: list[GlucoseReadingResponse]


class GlucoseSummaryPayload(BaseModel):
    startDate: datetime
    endDate: datetime
    targetLowMgdl: int
    targetHighMgdl: int
    averageMgdl: float | None = None
    timeInRangePercent: int | None = None
    readings: list[GlucoseReadingResponse]


class WeeklyGlucoseSummaryResponse(BaseModel):
    summary: GlucoseSummaryPayload
