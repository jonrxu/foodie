from functools import lru_cache

from app.clients.claude_client import ClaudeClient
from app.clients.dexcom_client import DexcomApiClient
from app.clients.instacart_client import InstacartClient
from app.config.settings import get_settings
from app.persistence.cart_store import SQLiteCartStore
from app.persistence.dexcom_store import SQLiteDexcomConnectionStore
from app.persistence.glucose_store import SQLiteGlucoseStore
from app.persistence.meal_store import SQLiteMealStore
from app.persistence.user_store import SQLiteUserStore
from app.services.cart_service import CartService
from app.services.cgm_service import CGMService
from app.services.dexcom_service import DexcomService
from app.services.meal_service import MealService
from app.services.user_service import UserService


@lru_cache(maxsize=1)
def get_user_store() -> SQLiteUserStore:
    return SQLiteUserStore(database_path=get_settings().backend_database_path)


@lru_cache(maxsize=1)
def get_user_service() -> UserService:
    return UserService(user_store=get_user_store())


@lru_cache(maxsize=1)
def get_dexcom_store() -> SQLiteDexcomConnectionStore:
    return SQLiteDexcomConnectionStore(database_path=get_settings().backend_database_path)


@lru_cache(maxsize=1)
def get_glucose_store() -> SQLiteGlucoseStore:
    return SQLiteGlucoseStore(database_path=get_settings().backend_database_path)


@lru_cache(maxsize=1)
def get_meal_store() -> SQLiteMealStore:
    return SQLiteMealStore(database_path=get_settings().backend_database_path)


@lru_cache(maxsize=1)
def get_cart_store() -> SQLiteCartStore:
    return SQLiteCartStore(database_path=get_settings().backend_database_path)


@lru_cache(maxsize=1)
def get_claude_client() -> ClaudeClient:
    return ClaudeClient(api_key=get_settings().anthropic_api_key)


@lru_cache(maxsize=1)
def get_instacart_client() -> InstacartClient:
    s = get_settings()
    return InstacartClient(api_key=s.instacart_api_key, mcp_url=s.instacart_mcp_url)


@lru_cache(maxsize=1)
def get_dexcom_client() -> DexcomApiClient:
    return DexcomApiClient(settings=get_settings())


@lru_cache(maxsize=1)
def get_dexcom_service() -> DexcomService:
    return DexcomService(settings=get_settings(), store=get_dexcom_store())


@lru_cache(maxsize=1)
def get_cgm_service() -> CGMService:
    return CGMService(
        dexcom_service=get_dexcom_service(),
        dexcom_client=get_dexcom_client(),
        glucose_store=get_glucose_store(),
    )


@lru_cache(maxsize=1)
def get_meal_service() -> MealService:
    return MealService(
        meal_store=get_meal_store(),
        glucose_store=get_glucose_store(),
        cgm_service=get_cgm_service(),
        dexcom_service=get_dexcom_service(),
        claude_client=get_claude_client(),
    )


@lru_cache(maxsize=1)
def get_cart_service() -> CartService:
    return CartService(
        settings=get_settings(),
        cart_store=get_cart_store(),
        meal_store=get_meal_store(),
        meal_service=get_meal_service(),
        claude_client=get_claude_client(),
        instacart_client=get_instacart_client(),
    )
