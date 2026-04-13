# Foodie

A glucose-aware food logging iOS app. Log meals via photo, voice, barcode, or text — the backend analyzes each meal with OpenAI, correlates it with CGM (Dexcom) glucose data, and generates personalized grocery recommendations.

---

## Architecture

```
Foodie/          → SwiftUI iOS app (MVVM)
backend/         → Python FastAPI backend (SQLite, OpenAI, Dexcom, Instacart)
```

The iOS app communicates with the backend over REST. All user state (meals, glucose readings, cart drafts) is persisted on the backend in SQLite. The app can run against the production Railway instance or a local server.

---

## iOS App

**Requirements:** Xcode 16+, iOS 18+, physical device recommended (camera features)

**Configuration** — set the backend URL in `Foodie/AppConfig.swift`:
```swift
static let defaultBackendBaseURL: String? = "https://your-backend.up.railway.app"
```

Or set the `FOODIE_BACKEND_URL` environment variable in the Xcode scheme to point at a local server.

**Build & Run:** Open `Foodie.xcodeproj`, select your target device, and run. No external package manager needed.

### iOS Codebase Layout

```
Foodie/
├── FoodieApp.swift              # App entry point, environment setup
├── AppConfig.swift              # Backend URL and default user ID
├── Domain/                      # Core models: MealLog, SpikeEvent, CartDraft, etc.
├── Models/                      # Supporting types: NutritionBreakdown, DateCodingStrategy
├── Views/
│   └── Prototype/               # All active UI: home, meal capture, feedback, cart, CGM
├── ViewModels/
│   ├── PrototypeMealFlowViewModel.swift   # Meal logging + insight loading
│   └── DexcomConnectionViewModel.swift    # CGM connection state
├── Services/
│   └── MealInsightEngine.swift  # Local fallback insight computation
├── Infrastructure/
│   └── API/
│       ├── BackendClient.swift  # All REST calls to the backend
│       └── APIEnvironment.swift # Switches between stub / remote modes
├── Repositories/                # Local SwiftData persistence (meals, glucose, carts)
└── Theme/                       # AppTheme colors and typography
```

**Key flows:**
- **Meal logging** → `MealCaptureView` → `PrototypeMealFlowViewModel.logMeal(input:)` → `POST /meals` → `GET /{id}/feedback`
- **CGM** → `DexcomConnectionViewModel` → `POST /dexcom/sync` + `GET /cgm/summary/weekly`
- **Cart** → `addSuggestedIngredientsToCart()` → `POST /cart/generate` or `POST /cart/generate-weekly`

---

## Backend

**Requirements:** Python 3.11+

**Install & run:**
```bash
cd backend
python -m venv .venv && source .venv/bin/activate
pip install -e ".[dev]"
cp .env.example .env        # fill in secrets
uvicorn app.main:app --reload --port 8000
```

### Environment Variables

| Variable | Required | Description |
|---|---|---|
| `OPENAI_API_KEY` | Yes | OpenAI API key |
| `OPENAI_MODEL` | No | Model name (default: `gpt-5.4`) |
| `DEXCOM_CLIENT_ID` | Yes (CGM) | Dexcom API client ID |
| `DEXCOM_CLIENT_SECRET` | Yes (CGM) | Dexcom API client secret |
| `DEXCOM_REDIRECT_URI` | Yes (CGM) | OAuth redirect URI (`foodie://dexcom/callback`) |
| `DEXCOM_AUTHORIZE_BASE` | No | Dexcom OAuth base (sandbox default) |
| `DEXCOM_TOKEN_URL` | No | Dexcom token endpoint |
| `DEXCOM_API_BASE` | No | Dexcom data API base |
| `DEXCOM_MOCK_OAUTH` | No | Skip real OAuth in dev (default: `true`) |
| `INSTACART_API_KEY` | Yes (cart) | Instacart MCP API key |
| `BACKEND_DATABASE_PATH` | No | SQLite file path (default: `data/foodie_backend.sqlite3`) |
| `API_BASE_URL` | No | Public URL of this server |

### Backend Codebase Layout

```
backend/app/
├── main.py                      # FastAPI app, router registration, CORS
├── scheduler.py                 # APScheduler (background glucose sync)
├── config/settings.py           # Pydantic Settings — all env vars
├── api/
│   ├── errors.py                # AppError exception handler
│   └── routes/
│       ├── health.py            # GET /healthz, /readyz
│       ├── users.py             # POST /users (register), GET /users/me
│       ├── dexcom.py            # OAuth start/callback, sync, status
│       ├── cgm.py               # GET /cgm/readings, /cgm/summary/weekly
│       ├── meals.py             # CRUD + analysis for meal logs
│       └── cart.py              # Cart generation + Instacart checkout
├── clients/
│   ├── openai_client.py         # Meal analysis, weekly cart via OpenAI
│   ├── dexcom_client.py         # Dexcom OAuth + EGV data fetching
│   └── instacart_client.py      # Instacart MCP for checkout URLs
├── services/
│   ├── meal_service.py          # Meal creation, glucose insight, cart items
│   ├── cgm_service.py           # Glucose window queries, Dexcom sync
│   ├── cart_service.py          # Per-meal and weekly cart orchestration
│   ├── dexcom_service.py        # Dexcom connection lifecycle
│   ├── user_service.py          # User registration and lookup
│   └── container.py             # Dependency injection / service wiring
├── persistence/                 # SQLite stores (one per domain)
│   ├── meal_store.py
│   ├── glucose_store.py
│   ├── cart_store.py
│   ├── dexcom_store.py
│   └── user_store.py
└── schemas/                     # Pydantic request/response models
    ├── meals.py
    ├── cgm.py
    ├── cart.py
    └── dexcom.py
```

### Key API Endpoints

| Method | Path | Description |
|---|---|---|
| `POST` | `/users` | Register a new user, returns UUID stored in iOS Keychain |
| `POST` | `/meals` | Log a meal; runs OpenAI analysis at write time |
| `GET` | `/meals/{id}/feedback` | Generate glucose insight + personalized coach message |
| `POST` | `/meals/analyze-photo` | Analyze a meal photo with OpenAI vision |
| `GET` | `/meals/recent` | Fetch recent meal logs |
| `POST` | `/dexcom/auth/start` | Start Dexcom OAuth |
| `GET` | `/dexcom/auth/callback` | OAuth callback, stores token |
| `POST` | `/dexcom/sync` | Pull latest CGM readings from Dexcom |
| `GET` | `/cgm/summary/weekly` | 7-day glucose summary |
| `POST` | `/cart/generate` | Per-meal grocery cart |
| `POST` | `/cart/generate-weekly` | Weekly grocery cart from meal history + CGM |
| `POST` | `/cart/checkout` | Generate Instacart checkout URL |

User identity is passed via the `X-User-Id` header on every request.

---

## Deployment (Railway)

The backend is deployed on Railway. A persistent volume is mounted at `/app/data` to preserve the SQLite database across deploys.

**Required env vars on Railway:** `OPENAI_API_KEY`, `DEXCOM_CLIENT_ID`, `DEXCOM_CLIENT_SECRET`, `DEXCOM_REDIRECT_URI`, `DEXCOM_AUTHORIZE_BASE`, `DEXCOM_TOKEN_URL`, `DEXCOM_API_BASE`, `INSTACART_API_KEY`, `BACKEND_DATABASE_PATH=/app/data/foodie_backend.sqlite3`

The deploy command is set in `backend/railway.toml`:
```toml
[deploy]
startCommand = "uvicorn app.main:app --host 0.0.0.0 --port $PORT"
healthcheckPath = "/healthz"
```

---

## How the AI Features Work

**At meal log time** (`POST /meals`): OpenAI analyzes the meal summary and stores `analysis` (nutrition estimates + suggested swap) directly on the meal record.

**At feedback time** (`GET /meals/{id}/feedback`): OpenAI generates a personalized coach message and food swap suggestions. If CGM data is available, a measured glucose spike is computed; otherwise a prediction is made from the nutrition data.

**Weekly cart** (`POST /cart/generate-weekly`): OpenAI receives the last 14 meal summaries, up to 5 glucose spike deltas, and the user's care goals and diet preferences. It returns 12–15 grocery items with rationale for each.
