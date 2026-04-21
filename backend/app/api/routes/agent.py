from fastapi import APIRouter, Depends, Query
from uuid import UUID

from app.api.dependencies import get_current_user_id
from app.schemas.agent import AgentFeedResponse, AgentRecommendationStateResponse
from app.services.agent_service import AgentService
from app.services.container import get_agent_service

router = APIRouter(prefix="/agent", tags=["agent"])


@router.get("/feed", response_model=AgentFeedResponse)
async def get_agent_feed(
    limit: int = Query(default=10, ge=1, le=50),
    user_id: str = Depends(get_current_user_id),
    service: AgentService = Depends(get_agent_service),
) -> AgentFeedResponse:
    return service.fetch_feed(user_id=user_id, limit=limit)


@router.post("/recommendations/{recommendation_id}/read", response_model=AgentRecommendationStateResponse)
async def mark_agent_recommendation_read(
    recommendation_id: UUID,
    user_id: str = Depends(get_current_user_id),
    service: AgentService = Depends(get_agent_service),
) -> AgentRecommendationStateResponse:
    return service.mark_recommendation_read(user_id=user_id, recommendation_id=recommendation_id)


@router.post("/recommendations/{recommendation_id}/dismiss", response_model=AgentRecommendationStateResponse)
async def dismiss_agent_recommendation(
    recommendation_id: UUID,
    user_id: str = Depends(get_current_user_id),
    service: AgentService = Depends(get_agent_service),
) -> AgentRecommendationStateResponse:
    return service.dismiss_recommendation(user_id=user_id, recommendation_id=recommendation_id)
