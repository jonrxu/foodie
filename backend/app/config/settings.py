from functools import lru_cache
from pathlib import Path

from pydantic import AnyHttpUrl
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_env: str = "local"
    app_name: str = "Foodie Backend"
    api_base_url: AnyHttpUrl = "http://localhost:8000"
    app_deep_link_base: str = "foodie://"
    backend_database_path: Path = Path("data/foodie_backend.sqlite3")
    instacart_handoff_base: AnyHttpUrl = "https://www.instacart.com/store/giant"

    dexcom_client_id: str = "replace-me"
    dexcom_client_secret: str = "replace-me"
    dexcom_redirect_uri: str = "http://localhost:8000/dexcom/connect/callback"
    dexcom_authorize_base: AnyHttpUrl = "https://sandbox-api.dexcom.com/v3/oauth2/login"
    dexcom_token_url: AnyHttpUrl = "https://sandbox-api.dexcom.com/v3/oauth2/token"
    dexcom_api_base: AnyHttpUrl = "https://sandbox-api.dexcom.com"
    dexcom_scope: str = "offline_access"
    dexcom_mock_oauth: bool = True

    openai_api_key: str = ""
    openai_model: str = "gpt-5.4"
    instacart_api_key: str = ""
    instacart_mcp_url: str = "https://mcp.dev.instacart.tools/mcp"

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings()
