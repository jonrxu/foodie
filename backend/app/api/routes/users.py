from fastapi import APIRouter, Depends

from app.api.dependencies import RequestUser, get_current_user
from app.schemas.users import UserProfileResponse, UserProfileUpdateRequest
from app.services.container import get_user_service
from app.services.user_service import UserService

router = APIRouter(prefix="/users", tags=["users"])


@router.get("/me", response_model=UserProfileResponse)
async def get_me(
    current_user: RequestUser = Depends(get_current_user),
    service: UserService = Depends(get_user_service),
) -> UserProfileResponse:
    if current_user.is_authenticated:
        return service.get_or_create_authenticated_user(current_user)
    return service.get_user(current_user.id)


@router.put("/me", response_model=UserProfileResponse)
async def update_me(
    payload: UserProfileUpdateRequest,
    current_user: RequestUser = Depends(get_current_user),
    service: UserService = Depends(get_user_service),
) -> UserProfileResponse:
    if not current_user.is_authenticated:
        return service.update_user(
            user_id=current_user.id,
            request=payload,
        )
    return service.update_authenticated_user(current_user, payload)
