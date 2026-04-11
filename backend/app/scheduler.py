from __future__ import annotations

import logging

from apscheduler.schedulers.background import BackgroundScheduler

logger = logging.getLogger(__name__)


def _run_weekly_carts() -> None:
    from app.schemas.cart import WeeklyCartRequest
    from app.services.container import get_cart_service, get_user_store

    user_store = get_user_store()
    cart_service = get_cart_service()
    request = WeeklyCartRequest()

    for user_id in user_store.list_user_ids():
        try:
            cart_service.generate_weekly_cart(user_id=user_id, request=request)
            logger.info("Generated weekly cart for user %s", user_id)
        except Exception as exc:
            logger.warning("Weekly cart failed for %s: %s", user_id, exc)


def create_scheduler() -> BackgroundScheduler:
    scheduler = BackgroundScheduler()
    scheduler.add_job(
        _run_weekly_carts,
        "cron",
        day_of_week="mon",
        hour=8,
        minute=0,
        id="weekly_cart",
        replace_existing=True,
    )
    return scheduler
