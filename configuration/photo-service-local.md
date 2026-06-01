# Photo service (local)

Repository: `sharingbridge-photo-service` (Python / FastAPI).

## Run locally

```powershell
cd D:\kannan\sharingbridge\sharingbridge-photo-service
python3.13 -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements-dev.txt
copy env.example .env
python -m pytest -q
```

| Variable | Purpose |
|----------|---------|
| `DATABASE_URL` | Same Postgres as integration-service |
| `AUTH_TOKEN_SECRET` | **Same** as user-service / integration-service |
| `CLOUDINARY_CLOUD_NAME` + key/secret | Or `CLOUDINARY_URL` |
| `PHOTO_UPLOAD_MOCK` | `true` = fake Cloudinary URLs (no account needed) |

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

Physical device on LAN: use your PC IP instead of `10.0.2.2` for photo-service.

## API

- `POST /v1/photos/upload` — multipart `file`, form `photo_type=seeker_reference`, Bearer JWT (donor)
- `GET /v1/photos/{artifact_id}` — donor (owner) or coordinator

Response includes `artifact_id`, `view_url`, `thumbnail_url` (Cloudinary).
