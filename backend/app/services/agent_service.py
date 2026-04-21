from __future__ import annotations

from dataclasses import dataclass
from datetime import UTC, date, datetime, time, timedelta
from uuid import UUID, uuid4

from app.api.errors import AppError
from app.persistence.agent_store import (
    SQLiteAgentStore,
    StoredAgentRecommendation,
    StoredAgentRun,
)
from app.persistence.glucose_store import SQLiteGlucoseStore
from app.persistence.meal_store import SQLiteMealStore
from app.schemas.cart import WeeklyCartRequest
from app.schemas.agent import (
    AgentFeedResponse,
    AgentRecommendationPayload,
    AgentRecommendationStateResponse,
    AgentRunPayload,
    NotificationDraftPayload,
)
from app.schemas.meals import MealLogPayload
from app.services.cart_service import CartService
from app.services.meal_service import MealService
from app.services.user_service import UserService


@dataclass
class DetectedSpike:
    started_at: datetime
    peak_at: datetime
    baseline_mgdl: int
    peak_mgdl: int
    delta_mgdl: int


class AgentService:
    SPIKE_KIND = "spike_triggered"

    def __init__(
        self,
        agent_store: SQLiteAgentStore,
        meal_store: SQLiteMealStore,
        glucose_store: SQLiteGlucoseStore,
        meal_service: MealService,
        cart_service: CartService,
        user_service: UserService,
    ) -> None:
        self.agent_store = agent_store
        self.meal_store = meal_store
        self.glucose_store = glucose_store
        self.meal_service = meal_service
        self.cart_service = cart_service
        self.user_service = user_service

    def process_recent_spikes(self, user_id: str, *, lookback_hours: int = 6) -> int:
        end = datetime.now(UTC)
        start = end - timedelta(hours=lookback_hours)
        readings = self.glucose_store.fetch_readings(user_id=user_id, start=start, end=end)
        spikes = self._detect_spikes(readings)
        recommendations_created = 0

        for spike in spikes:
            source_event_key = f"spike:{spike.started_at.isoformat()}:{spike.peak_at.isoformat()}:{spike.peak_mgdl}"
            if self.agent_store.has_run_for_source_event(user_id, self.SPIKE_KIND, source_event_key):
                continue

            recommendation = self._build_spike_recommendation(user_id=user_id, spike=spike)
            completed_at = datetime.now(UTC)
            run = StoredAgentRun(
                id=str(uuid4()),
                kind=self.SPIKE_KIND,
                status="completed",
                created_at=completed_at,
                completed_at=completed_at,
                summary=recommendation.summary,
                source_event_key=source_event_key,
                recommendations_created=1,
            )
            self.agent_store.insert_run(user_id=user_id, run=run)
            self.agent_store.insert_recommendation(
                user_id=user_id,
                recommendation=StoredAgentRecommendation(
                    id=str(recommendation.id),
                    run_id=run.id,
                    created_at=recommendation.createdAt,
                    title=recommendation.title,
                    summary=recommendation.summary,
                    read_at=None,
                    dismissed_at=None,
                    payload=recommendation.model_dump(mode="json"),
                ),
                notification_payload=(
                    recommendation.notificationDraft.model_dump(mode="json")
                    if recommendation.notificationDraft is not None
                    else None
                ),
            )
            recommendations_created += 1

        return recommendations_created

    def fetch_feed(self, user_id: str, limit: int = 10) -> AgentFeedResponse:
        runs = [
            AgentRunPayload(
                id=UUID(run.id),
                kind=run.kind,
                status=run.status,
                createdAt=run.created_at,
                completedAt=run.completed_at,
                summary=run.summary,
                sourceEventKey=run.source_event_key,
                recommendationsCreated=run.recommendations_created,
            )
            for run in self.agent_store.fetch_recent_runs(user_id=user_id, limit=limit)
        ]
        recommendations = []
        for row in self.agent_store.fetch_recent_recommendations(user_id=user_id, limit=limit):
            payload = dict(row["payload"])
            if row["notification_payload"] is not None:
                payload["notificationDraft"] = row["notification_payload"]
            payload["readAt"] = row["read_at"]
            payload["dismissedAt"] = row["dismissed_at"]
            recommendations.append(AgentRecommendationPayload.model_validate(payload))
        return AgentFeedResponse(runs=runs, recommendations=recommendations)

    def mark_recommendation_read(self, user_id: str, recommendation_id: UUID) -> AgentRecommendationStateResponse:
        stored = self.agent_store.mark_recommendation_read(
            user_id=user_id,
            recommendation_id=str(recommendation_id),
            read_at=datetime.now(UTC),
        )
        if stored is None:
            raise AppError(code="agent_recommendation_not_found", message="Recommendation not found.", status_code=404)
        return AgentRecommendationStateResponse(
            id=UUID(stored.id),
            readAt=stored.read_at,
            dismissedAt=stored.dismissed_at,
        )

    def dismiss_recommendation(self, user_id: str, recommendation_id: UUID) -> AgentRecommendationStateResponse:
        stored = self.agent_store.dismiss_recommendation(
            user_id=user_id,
            recommendation_id=str(recommendation_id),
            dismissed_at=datetime.now(UTC),
        )
        if stored is None:
            raise AppError(code="agent_recommendation_not_found", message="Recommendation not found.", status_code=404)
        return AgentRecommendationStateResponse(
            id=UUID(stored.id),
            readAt=stored.read_at,
            dismissedAt=stored.dismissed_at,
        )

    def process_daily_summary(self, user_id: str, *, target_date: date | None = None) -> int:
        day = target_date or (datetime.now(UTC).date() - timedelta(days=1))
        source_event_key = f"daily:{day.isoformat()}"
        if self.agent_store.has_run_for_source_event(user_id, "daily_summary", source_event_key):
            return 0

        day_start = datetime.combine(day, time.min, tzinfo=UTC)
        day_end = datetime.combine(day, time.max, tzinfo=UTC)
        readings = self.glucose_store.fetch_readings(user_id=user_id, start=day_start, end=day_end)
        meals = self.meal_store.fetch_meals_between(user_id=user_id, start=day_start, end=day_end)
        spikes = self._detect_spikes(readings)

        if not readings:
            self._store_skipped_run(
                user_id=user_id,
                kind="daily_summary",
                source_event_key=source_event_key,
                summary=f"No CGM data was available for {day.isoformat()}.",
            )
            return 0

        tir = round(
            (
                len([reading for reading in readings if 70 <= reading.value_mgdl <= 180])
                / len(readings)
            )
            * 100
        )
        notable = tir < 85 or len(spikes) > 0
        if not notable:
            self._store_skipped_run(
                user_id=user_id,
                kind="daily_summary",
                source_event_key=source_event_key,
                summary=f"{day.isoformat()} was stable with {tir}% time in range and no notable spikes.",
            )
            return 0

        created_at = datetime.now(UTC)
        summary = self._daily_summary_text(day=day, tir=tir, spike_count=len(spikes), meal_count=len(meals))
        recommendation = AgentRecommendationPayload(
            id=uuid4(),
            createdAt=created_at,
            runKind="daily_summary",
            title="Daily glucose summary",
            summary=summary,
            actionLabel="View CGM",
            notificationDraft=NotificationDraftPayload(
                id=uuid4(),
                kind="daily_summary_ready",
                title="Daily summary ready",
                body=summary,
                createdAt=created_at,
                actionLabel="Open summary",
                targetPath="/cgm",
            ),
        )
        run = StoredAgentRun(
            id=str(uuid4()),
            kind="daily_summary",
            status="completed",
            created_at=created_at,
            completed_at=created_at,
            summary=summary,
            source_event_key=source_event_key,
            recommendations_created=1,
        )
        self.agent_store.insert_run(user_id=user_id, run=run)
        self.agent_store.insert_recommendation(
            user_id=user_id,
            recommendation=StoredAgentRecommendation(
                id=str(recommendation.id),
                run_id=run.id,
                created_at=recommendation.createdAt,
                title=recommendation.title,
                summary=recommendation.summary,
                read_at=None,
                dismissed_at=None,
                payload=recommendation.model_dump(mode="json"),
            ),
            notification_payload=recommendation.notificationDraft.model_dump(mode="json"),
        )
        return 1

    def process_weekly_summary(self, user_id: str, *, anchor_date: date | None = None) -> int:
        anchor = anchor_date or datetime.now(UTC).date()
        week_end = datetime.combine(anchor, time.max, tzinfo=UTC)
        week_start = week_end - timedelta(days=7)
        source_event_key = f"weekly:{anchor.isoformat()}"
        if self.agent_store.has_run_for_source_event(user_id, "weekly_planning", source_event_key):
            return 0

        readings = self.glucose_store.fetch_readings(user_id=user_id, start=week_start, end=week_end)
        daily_runs = self.agent_store.fetch_runs_between(
            user_id=user_id,
            start=week_start,
            end=week_end,
            kind="daily_summary",
        )
        daily_recommendations = self.agent_store.fetch_recommendations_between(
            user_id=user_id,
            start=week_start,
            end=week_end,
            run_kind="daily_summary",
        )
        meals = self.meal_store.fetch_recent_meals(user_id=user_id, limit=21)
        meals_in_window = [meal for meal in meals if week_start <= meal.logged_at <= week_end]

        if not readings and not meals_in_window:
            self._store_skipped_run(
                user_id=user_id,
                kind="weekly_planning",
                source_event_key=source_event_key,
                summary="Weekly planning skipped because there was no recent CGM or meal data.",
            )
            return 0

        user = self.user_service.get_user(user_id)
        weekly_cart = self.cart_service.generate_weekly_cart(
            user_id=user_id,
            request=WeeklyCartRequest(
                careGoals=user.careGoals,
                dietPreferences=user.dietPreferences,
            ),
        )
        tir = None
        if readings:
            tir = round(
                (
                    len([reading for reading in readings if 70 <= reading.value_mgdl <= 180])
                    / len(readings)
                )
                * 100
            )
        created_at = datetime.now(UTC)
        summary = self._weekly_summary_text(
            tir=tir,
            meal_count=len(meals_in_window),
            daily_summary_count=len([run for run in daily_runs if run.status == "completed"]),
            insight_count=len(daily_recommendations),
            cart_item_count=len(weekly_cart.draft.items if weekly_cart.draft else []),
        )
        recommendation = AgentRecommendationPayload(
            id=uuid4(),
            createdAt=created_at,
            runKind="weekly_planning",
            title="Weekly check-in",
            summary=summary,
            actionLabel="Open cart",
            notificationDraft=NotificationDraftPayload(
                id=uuid4(),
                kind="weekly_plan_ready",
                title="Weekly plan is ready",
                body=summary,
                createdAt=created_at,
                actionLabel="View cart",
                targetPath="/cart",
            ),
        )
        run = StoredAgentRun(
            id=str(uuid4()),
            kind="weekly_planning",
            status="completed",
            created_at=created_at,
            completed_at=created_at,
            summary=summary,
            source_event_key=source_event_key,
            recommendations_created=1,
        )
        self.agent_store.insert_run(user_id=user_id, run=run)
        self.agent_store.insert_recommendation(
            user_id=user_id,
            recommendation=StoredAgentRecommendation(
                id=str(recommendation.id),
                run_id=run.id,
                created_at=recommendation.createdAt,
                title=recommendation.title,
                summary=recommendation.summary,
                read_at=None,
                dismissed_at=None,
                payload=recommendation.model_dump(mode="json"),
            ),
            notification_payload=recommendation.notificationDraft.model_dump(mode="json"),
        )
        return 1

    def _build_spike_recommendation(self, user_id: str, spike: DetectedSpike) -> AgentRecommendationPayload:
        created_at = datetime.now(UTC)
        nearby_meals = self.meal_store.fetch_meals_between(
            user_id=user_id,
            start=spike.started_at - timedelta(hours=2),
            end=spike.started_at + timedelta(minutes=30),
        )
        meal = nearby_meals[-1] if nearby_meals else None

        if meal is None:
            notification = NotificationDraftPayload(
                id=uuid4(),
                kind="log_meal_prompt",
                title="Log what you ate",
                body="We noticed a glucose rise and could not find a nearby meal log. Add it so Foodie can explain what happened.",
                createdAt=created_at,
                actionLabel="Log meal",
                targetPath="/food",
            )
            return AgentRecommendationPayload(
                id=uuid4(),
                createdAt=created_at,
                runKind=self.SPIKE_KIND,
                title="Glucose rise detected",
                summary="A recent spike did not have a nearby food log, so the next best step is to ask the user to log the meal.",
                actionLabel="Log meal",
                relatedSpikeStartedAt=spike.started_at,
                notificationDraft=notification,
            )

        meal_payload = MealLogPayload.model_validate(meal.payload)
        insight = self.meal_service.fetch_meal_insight(user_id=user_id, meal_id=meal_payload.id)
        notification = NotificationDraftPayload(
            id=uuid4(),
            kind="meal_feedback_ready",
            title="Meal feedback is ready",
            body=insight.feedback.summary,
            createdAt=created_at,
            actionLabel="View feedback",
            targetPath=f"/meals/{meal_payload.id}",
            relatedMealLogID=meal_payload.id,
        )
        return AgentRecommendationPayload(
            id=uuid4(),
            createdAt=created_at,
            runKind=self.SPIKE_KIND,
            title=f"Review meal: {meal_payload.summary}",
            summary=insight.feedback.coachMessage,
            actionLabel="View feedback",
            relatedMealLogID=meal_payload.id,
            relatedSpikeStartedAt=spike.started_at,
            notificationDraft=notification,
        )

    def _store_skipped_run(self, *, user_id: str, kind: str, source_event_key: str, summary: str) -> None:
        created_at = datetime.now(UTC)
        self.agent_store.insert_run(
            user_id=user_id,
            run=StoredAgentRun(
                id=str(uuid4()),
                kind=kind,
                status="skipped",
                created_at=created_at,
                completed_at=created_at,
                summary=summary,
                source_event_key=source_event_key,
                recommendations_created=0,
            ),
        )

    @staticmethod
    def _daily_summary_text(*, day: date, tir: int, spike_count: int, meal_count: int) -> str:
        spike_phrase = "1 notable spike" if spike_count == 1 else f"{spike_count} notable spikes"
        meal_phrase = "1 logged meal" if meal_count == 1 else f"{meal_count} logged meals"
        if spike_count == 0:
            spike_phrase = "no notable spikes"
        return (
            f"On {day.strftime('%A')}, you were in range {tir}% of the day with "
            f"{spike_phrase} across {meal_phrase}."
        )

    @staticmethod
    def _weekly_summary_text(
        *,
        tir: int | None,
        meal_count: int,
        daily_summary_count: int,
        insight_count: int,
        cart_item_count: int,
    ) -> str:
        tir_phrase = f"{tir}% time in range" if tir is not None else "limited CGM coverage"
        return (
            f"This week included {meal_count} logged meals, {daily_summary_count} notable daily check-ins, "
            f"and {tir_phrase}. Foodie used {insight_count} daily insights to build a grocery cart with "
            f"{cart_item_count} items."
        )

    def _detect_spikes(self, readings: list) -> list[DetectedSpike]:
        if len(readings) < 5:
            return []

        spikes: list[DetectedSpike] = []
        active_start = None
        active_baseline = None
        active_peak = None

        for index, reading in enumerate(readings):
            window_start = max(0, index - 4)
            baseline = min(item.value_mgdl for item in readings[window_start : index + 1])
            delta = reading.value_mgdl - baseline
            above_threshold = reading.value_mgdl >= 180 and delta >= 30

            if above_threshold and active_start is None:
                active_start = reading.timestamp
                active_baseline = baseline
                active_peak = reading
                continue

            if above_threshold and active_peak is not None and reading.value_mgdl >= active_peak.value_mgdl:
                active_peak = reading
                continue

            if active_start is not None and active_peak is not None:
                spikes.append(
                    DetectedSpike(
                        started_at=active_start,
                        peak_at=active_peak.timestamp,
                        baseline_mgdl=int(active_baseline or active_peak.value_mgdl),
                        peak_mgdl=int(active_peak.value_mgdl),
                        delta_mgdl=int((active_peak.value_mgdl - (active_baseline or active_peak.value_mgdl))),
                    )
                )
                active_start = None
                active_baseline = None
                active_peak = None

        if active_start is not None and active_peak is not None:
            spikes.append(
                DetectedSpike(
                    started_at=active_start,
                    peak_at=active_peak.timestamp,
                    baseline_mgdl=int(active_baseline or active_peak.value_mgdl),
                    peak_mgdl=int(active_peak.value_mgdl),
                    delta_mgdl=int((active_peak.value_mgdl - (active_baseline or active_peak.value_mgdl))),
                )
            )

        return spikes[-3:]
