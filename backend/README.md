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
# Set a Supabase access token first
export SUPABASE_JWT="paste-user-access-token-here"

# 1) start Dexcom connection
curl -s -X POST -H "Authorization: Bearer $SUPABASE_JWT" http://localhost:8000/dexcom/connect/start | jq

# 2) check status for a user
curl -s -H "Authorization: Bearer $SUPABASE_JWT" http://localhost:8000/dexcom/connect/status | jq

# 3) mock complete (temporary)
curl -s -X POST -H "Authorization: Bearer $SUPABASE_JWT" http://localhost:8000/dexcom/connect/mock-complete | jq

# 4) trigger sync
curl -s -X POST -H "Authorization: Bearer $SUPABASE_JWT" http://localhost:8000/dexcom/sync | jq

# 5) disconnect
curl -s -X POST -H "Authorization: Bearer $SUPABASE_JWT" http://localhost:8000/dexcom/disconnect | jq
```

## Notes

- Dexcom connection state and tokens now persist in a local SQLite file at `data/foodie_backend.sqlite3`.
- OAuth callback now issues a redirect to the app deep link instead of returning JSON.
- Production Dexcom is now the default path. Use valid production credentials with:
  - `DEXCOM_CLIENT_ID`
  - `DEXCOM_CLIENT_SECRET`
  - `DEXCOM_REDIRECT_URI`
- Sandbox is still available if you explicitly set:
  - `DEXCOM_AUTHORIZE_BASE=https://sandbox-api.dexcom.com/v3/oauth2/login`
  - `DEXCOM_TOKEN_URL=https://sandbox-api.dexcom.com/v3/oauth2/token`
  - `DEXCOM_API_BASE=https://sandbox-api.dexcom.com`
  - `DEXCOM_MOCK_OAUTH=true`
- `POST /dexcom/sync` now pulls mock or real Dexcom glucose data and persists it to SQLite.
- This is still prototype-grade persistence and should be replaced with Postgres-backed repositories before production use.
