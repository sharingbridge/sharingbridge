# Photo service (local)

Repository: `sharingbridge-photo-service` (Python / FastAPI).

## Run locally

```powershell
cd D:\kannan\sharingbridge\sharingbridge-photo-service
python3.13 -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements-dev.txt
copy env.example .env
# Edit .env before pytest or uvicorn (DATABASE_URL, AUTH_TOKEN_SECRET, CLOUDINARY_* required)
python -m pytest -q
```

Variables: [environment-variables.md](./environment-variables.md) § `sharingbridge-photo-service`. Use same `DATABASE_URL` and `AUTH_TOKEN_SECRET` as user-service.

```powershell
uvicorn app.main:app --reload --port 8092
```

Health: `http://localhost:8092/health`

## Mobile

```powershell
flutter run -d <device> `
  --dart-define=PHOTO_SERVICE_BASE_URL=http://10.0.2.2:8092 `
  --dart-define=API_BASE_URL=http://10.0.2.2:8080 `
  --dart-define=USER_SERVICE_BASE_URL=http://10.0.2.2:8081 `
  --dart-define=GOOGLE_CLIENT_ID=...
```

**Physical device:** use your PC’s Wi‑Fi IPv4 for **all** services (`USER_SERVICE`, `API`, `PHOTO`) — same Wi‑Fi as the PC. See [mobile-client.md](./mobile-client.md) § Local networking and [MANUAL_TESTING_GUIDE.md](../testing/MANUAL_TESTING_GUIDE.md) §3-host.

## API

- `POST /v1/photos/upload` — multipart `file`, form `photo_type=seeker_reference`, Bearer JWT (donor)
- `GET /v1/photos/{artifact_id}` — donor (owner) or coordinator

Response includes `artifact_id`, `view_url`, `thumbnail_url` (Cloudinary).
