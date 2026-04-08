from uuid import UUID

from fastapi import APIRouter, Depends, Query

from app.api.dependencies import get_current_user_id
from app.schemas.meals import MealInsightResponse, MealLogPayload, RecentMealsResponse
from app.services.container import get_meal_service
from app.services.meal_service import MealService

router = APIRouter(prefix="/meals", tags=["meals"])


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


@router.get("/{meal_id}/feedback", response_model=MealInsightResponse)
async def get_meal_feedback(
    meal_id: UUID,
    user_id: str = Depends(get_current_user_id),
    service: MealService = Depends(get_meal_service),
) -> MealInsightResponse:
    return service.fetch_meal_insight(user_id=user_id, meal_id=meal_id)
