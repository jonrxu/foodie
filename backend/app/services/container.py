from functools import lru_cache

from app.clients.dexcom_client import DexcomApiClient
from app.config.settings import get_settings
from app.persistence.dexcom_store import SQLiteDexcomConnectionStore
from app.persistence.glucose_store import SQLiteGlucoseStore
from app.services.cgm_service import CGMService
from app.services.dexcom_service import DexcomService


@lru_cache(maxsize=1)
def get_dexcom_store() -> SQLiteDexcomConnectionStore:
    return SQLiteDexcomConnectionStore(database_path=get_settings().backend_database_path)


@lru_cache(maxsize=1)
def get_glucose_store() -> SQLiteGlucoseStore:
    return SQLiteGlucoseStore(database_path=get_settings().backend_database_path)


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
