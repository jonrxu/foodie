# Foodie Backend (Scaffold)

This backend scaffold is aligned to `docs/backend-spec.md` and now includes a fuller Dexcom prototype lifecycle.

## Implemented endpoints

### Health
- `GET /healthz`
- `GET /readyz`

### Dexcom (prototype)
- `POST /dexcom/connect/start`
- `GET /dexcom/connect/callback`
- `GET /dexcom/connect/status`
- `POST /dexcom/sync`
- `POST /dexcom/disconnect`
- `POST /dexcom/connect/mock-complete` (temporary helper for iOS demo wiring)

### CGM (prototype)
- `GET /cgm/summary/weekly`
- `GET /cgm/readings`

## Run locally

```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -e .[dev]
uvicorn app.main:app --reload --port 8000
```

## Example flow

```bash
# 1) start Dexcom connection
curl -s -X POST http://localhost:8000/dexcom/connect/start | jq

# 2) check status for a user
curl -s -H 'X-User-Id: demo-user' http://localhost:8000/dexcom/connect/status | jq

# 3) mock complete (temporary)
curl -s -X POST -H 'X-User-Id: demo-user' http://localhost:8000/dexcom/connect/mock-complete | jq

# 4) trigger sync
curl -s -X POST -H 'X-User-Id: demo-user' http://localhost:8000/dexcom/sync | jq

# 5) disconnect
curl -s -X POST -H 'X-User-Id: demo-user' http://localhost:8000/dexcom/disconnect | jq
```

## Notes

- Dexcom connection state and tokens now persist in a local SQLite file at `data/foodie_backend.sqlite3`.
- OAuth callback now issues a redirect to the app deep link instead of returning JSON.
- Real Dexcom token exchange is enabled when `DEXCOM_MOCK_OAUTH=false` and valid Dexcom client credentials are provided.
- `POST /dexcom/sync` now pulls mock or real Dexcom glucose data and persists it to SQLite.
- This is still prototype-grade persistence and should be replaced with Postgres-backed repositories before production use.
