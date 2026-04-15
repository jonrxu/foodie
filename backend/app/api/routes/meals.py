from uuid import UUID

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel

from app.api.dependencies import get_current_user_id
from app.schemas.meals import MealInsightResponse, MealLogPayload, RecentMealsResponse
from app.services.container import get_meal_service
from app.services.meal_service import MealService

router = APIRouter(prefix="/meals", tags=["meals"])


class AnalyzePhotoRequest(BaseModel):
    imageBase64: str
    mimeType: str = "image/jpeg"


class AnalyzePhotoResponse(BaseModel):
    summary: str
    servingSize: str | None = None
    calories: int | None = None


class LookupBarcodeResponse(BaseModel):
    summary: str


@router.post("", response_model=MealLogPayload)
async def create_meal(
    payload: MealLogPayload,
    user_id: str = Depends(get_current_user_id),
    service: MealService = Depends(get_meal_service),
) -> MealLogPayload:
    return service.create_meal(user_id=user_id, meal=payload)


@router.get("/recent", response_model=RecentMealsResponse)
async def get_recent_meals(
    limit: int = Query(default=10, ge=1, le=50),
    user_id: str = Depends(get_current_user_id),
    service: MealService = Depends(get_meal_service),
) -> RecentMealsResponse:
    return service.fetch_recent_meals(user_id=user_id, limit=limit)


@router.post("/analyze-photo", response_model=AnalyzePhotoResponse)
async def analyze_photo(
    payload: AnalyzePhotoRequest,
    user_id: str = Depends(get_current_user_id),
    service: MealService = Depends(get_meal_service),
) -> AnalyzePhotoResponse:
    summary, serving_size, calories = service.analyze_photo(payload.imageBase64, payload.mimeType)
    return AnalyzePhotoResponse(summary=summary, servingSize=serving_size, calories=calories)


@router.get("/lookup-barcode", response_model=LookupBarcodeResponse)
async def lookup_barcode(
    code: str = Query(...),
    user_id: str = Depends(get_current_user_id),
    service: MealService = Depends(get_meal_service),
) -> LookupBarcodeResponse:
    summary = service.lookup_barcode(code)
    return LookupBarcodeResponse(summary=summary)


@router.get("/{meal_id}/feedback", response_model=MealInsightResponse)
async def get_meal_feedback(
    meal_id: UUID,
    user_id: str = Depends(get_current_user_id),
    service: MealService = Depends(get_meal_service),
) -> MealInsightResponse:
    return service.fetch_meal_insight(user_id=user_id, meal_id=meal_id)
