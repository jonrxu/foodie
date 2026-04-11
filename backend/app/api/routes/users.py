from fastapi import APIRouter, Depends

from app.api.dependencies import get_current_user_id
from app.schemas.users import UserProfileResponse, UserRegistrationRequest
from app.services.container import get_user_service
from app.services.user_service import UserService

router = APIRouter(prefix="/users", tags=["users"])


@router.post("/register", response_model=UserProfileResponse)
async def register_user(
    payload: UserRegistrationRequest,
    service: UserService = Depends(get_user_service),
) -> UserProfileResponse:
    """Create a new user account. No auth header required — returns a stable user ID to store on the client."""
    return service.register_user(payload)


@router.get("/me", response_model=UserProfileResponse)
async def get_me(
    user_id: str = Depends(get_current_user_id),
    service: UserService = Depends(get_user_service),
) -> UserProfileResponse:
    return service.get_user(user_id)
