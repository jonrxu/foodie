from fastapi import Header

from app.config.settings import Settings, get_settings


async def get_current_user_id(x_user_id: str | None = Header(default=None)) -> str:
    """Prototype auth shim.

    Replaced later with JWT/session auth.
    """
    return x_user_id or "demo-user"


def settings_dependency() -> Settings:
    return get_settings()
