from __future__ import annotations

import logging
from datetime import UTC, datetime, timedelta

from apscheduler.schedulers.background import BackgroundScheduler

logger = logging.getLogger(__name__)


def _run_weekly_carts() -> None:
    from app.services.container import get_agent_service, get_user_store

    user_store = get_user_store()
    agent_service = get_agent_service()

    for user_id in user_store.list_user_ids():
        try:
            agent_service.process_weekly_summary(user_id=user_id)
            logger.info("Generated weekly summary for user %s", user_id)
        except Exception as exc:
            logger.warning("Weekly summary failed for %s: %s", user_id, exc)


def _run_daily_summaries() -> None:
    from app.services.container import get_agent_service, get_user_store

    user_store = get_user_store()
    agent_service = get_agent_service()
    target_date = (datetime.now(UTC) - timedelta(days=1)).date()

    for user_id in user_store.list_user_ids():
        try:
            agent_service.process_daily_summary(user_id=user_id, target_date=target_date)
            logger.info("Generated daily summary for user %s on %s", user_id, target_date)
        except Exception as exc:
            logger.warning("Daily summary failed for %s: %s", user_id, exc)


def create_scheduler() -> BackgroundScheduler:
    scheduler = BackgroundScheduler()
    scheduler.add_job(
        _run_daily_summaries,
        "cron",
        hour=3,
        minute=0,
        id="daily_summary",
        replace_existing=True,
    )
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
