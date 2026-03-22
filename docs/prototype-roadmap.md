# Foodie Prototype Roadmap

## Goal
Turn the current mockup-driven app into a functioning diabetes-support prototype with:

- onboarding
- food logging
- CGM ingestion from Dexcom
- spike-triggered meal feedback
- grocery planning
- Instacart checkout handoff
- an AI planning layer using MCP

## Current State

- The app currently launches into a demo/mock flow.
- CGM views are mock-data only.
- Food logging exists, but meal logs are not linked to glucose events.
- Instacart integration exists as a demo-grade client-side MCP wrapper.
- Secrets are stored in `UserDefaults`.
- There is no backend for Dexcom OAuth, token storage, or server-side orchestration.

## Architecture Direction

Use a thin iOS client plus a backend.

- iOS app:
  - onboarding
  - dashboard
  - food logging
  - CGM summaries
  - meal feedback
  - cart review
  - Instacart handoff
- backend:
  - Dexcom OAuth and token refresh
  - CGM sync
  - spike detection
  - meal feedback generation
  - grocery/cart generation
  - OpenAI Responses agent
  - Instacart MCP / shopping-list integration

## Implementation Order

1. unify the app shell
2. replace demo-only routing with a real session-driven shell
3. introduce real domain models for meals, glucose, spikes, and carts
4. replace ad hoc persistence with repositories and secure storage
5. stand up a backend
6. integrate Dexcom sandbox
7. build deterministic spike detection
8. connect live feedback to food logs + glucose
9. replace mock cart generation with structured planning
10. integrate Instacart checkout handoff
11. add the AI agent with MCP for planning/refinement
12. add push/event notifications
13. add tests and demo hardening

## Epics

### Epic 0: Core App Spine

- Build one real app shell
- Move mockups into reference/demo-only status
- Route onboarding, home, logging, CGM, feedback, groceries, and profile through one coordinator

### Epic 1: Domain Model Rewrite

Add real models for:

- `PatientProfile`
- `MealLog`
- `MealAsset`
- `MealAnalysis`
- `GlucoseReading`
- `GlucoseSummary`
- `SpikeEvent`
- `MealFeedback`
- `CartDraft`
- `ExternalConnection`

### Epic 2: Security and Config

- move secrets to Keychain
- add environment config
- fix Info.plist usage strings

### Epic 3: Backend Scaffold

Backend responsibilities:

- Dexcom auth
- CGM sync
- spike detection
- meal feedback
- cart generation
- Instacart handoff
- OpenAI agent orchestration

### Epic 4: Dexcom Integration

- Dexcom sandbox auth
- token refresh on backend
- EGV sync
- weekly summaries
- connection status in app

### Epic 5: Food Logging

- photo, voice, and text ingestion
- structured parsing
- user confirmation/edit step
- persistent meal records

### Epic 6: Spike Detection

- meal-to-glucose attribution windows
- baseline / peak / delta / return-to-range calculations
- prompt-worthy event rules

### Epic 7: Feedback Screen

- live meal feedback
- measured spike when available
- predicted spike fallback when not available
- one simple recommended swap

### Epic 8: Grocery and Meal Planning

- generate groceries from meal history + CGM summaries + profile
- editable cart review
- weekly meal planning path

### Epic 9: Instacart Integration

- direct checkout handoff first
- backend-owned credentials
- shopping list / checkout URL generation

### Epic 10: AI Agent with MCP

- OpenAI Responses-based agent
- remote Instacart MCP connection
- structured meal-planning and cart-refinement flows

### Epic 11: Notifications and Background Sync

- spike-based prompts
- backend-triggered notifications
- reminder fallback

### Epic 12: QA and Demo Hardening

- unit tests
- repository tests
- API contract tests
- one end-to-end UI test
- demo reset + seed mode

## Sprint 1

Focus on the foundation.

- save the roadmap in-repo
- replace the demo flow as the main app shell
- inject real app session state at app launch
- create a prototype shell that can own onboarding and home
- keep existing mock views as reusable visual surfaces for now

## Sprint 2

- backend scaffold
- Dexcom sandbox auth
- CGM sync pipeline
- live weekly CGM screen

## Sprint 3

- real meal logging persistence
- spike detection engine
- live meal feedback

## Sprint 4

- grocery planning from meals + CGM
- Instacart direct handoff
- “add ingredients to cart” real path

## Sprint 5

- OpenAI agent
- Instacart MCP refinement flow
- event-driven prompts

## Immediate Next Steps

1. replace `RootView` with a session-driven prototype shell
2. inject `AppSession` and `UserPreferences` at app launch
3. move the current integrated demo flow into a reusable prototype shell
4. start introducing real models and repositories behind the UI
