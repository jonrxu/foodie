from fastapi import APIRouter, Depends

from app.api.dependencies import get_current_user_id
from app.schemas.cart import CartCheckoutRequest, CartDraftEnvelope, CartGenerationRequest, WeeklyCartRequest
from app.services.cart_service import CartService
from app.services.container import get_cart_service

router = APIRouter(prefix="/cart", tags=["cart"])


@router.post("/generate", response_model=CartDraftEnvelope)
async def generate_cart(
    payload: CartGenerationRequest,
    user_id: str = Depends(get_current_user_id),
    service: CartService = Depends(get_cart_service),
) -> CartDraftEnvelope:
    return service.generate_cart(user_id=user_id, request=payload)


@router.get("/latest", response_model=CartDraftEnvelope)
async def get_latest_cart(
    user_id: str = Depends(get_current_user_id),
    service: CartService = Depends(get_cart_service),
) -> CartDraftEnvelope:
    return service.fetch_latest_cart(user_id=user_id)


@router.post("/generate-weekly", response_model=CartDraftEnvelope)
async def generate_weekly_cart(
    payload: WeeklyCartRequest,
    user_id: str = Depends(get_current_user_id),
    service: CartService = Depends(get_cart_service),
) -> CartDraftEnvelope:
    return service.generate_weekly_cart(user_id=user_id, request=payload)


@router.post("/checkout", response_model=CartDraftEnvelope)
async def prepare_checkout(
    payload: CartCheckoutRequest,
    user_id: str = Depends(get_current_user_id),
    service: CartService = Depends(get_cart_service),
) -> CartDraftEnvelope:
    return service.prepare_checkout(user_id=user_id, request=payload)
