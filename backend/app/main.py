from fastapi import FastAPI

from app.api.errors import register_exception_handlers
from app.api.routes.cart import router as cart_router
from app.api.routes.cgm import router as cgm_router
from app.api.routes.dexcom import router as dexcom_router
from app.api.routes.health import router as health_router
from app.api.routes.meals import router as meals_router
from app.api.routes.users import router as users_router
from app.config.settings import get_settings

settings = get_settings()

app = FastAPI(title=settings.app_name, version="0.2.0")
register_exception_handlers(app)
app.include_router(health_router)
app.include_router(users_router)
app.include_router(dexcom_router)
app.include_router(cgm_router)
app.include_router(meals_router)
app.include_router(cart_router)
