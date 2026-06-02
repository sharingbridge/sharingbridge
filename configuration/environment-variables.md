# Environment variables (dev unlocks & MVP web access)

**Single reference** for optional dev/MVP flags. Per-repo templates: `env.example` → `.env` (gitignored).

| | Local dev | Render production | Render staging (optional MVP) |
|--|-----------|-------------------|-------------------------------|
| **user-service** `ALLOW_DEV_TOKEN_MINT` | `true` | omit / `false` | `true` if needed |
| **user-service** `ALLOW_WEB_DASHBOARD_ANY_USER` | `true` if testing donor-on-web | omit / `false` | `true` |
| **user-service** `DEPLOYMENT_ENV` | omit or `development` | `production` (blueprint default) | `staging` |
| **web** `VITE_ALLOW_DEV_SIGN_IN` | `true` if skipping Google | omit | `true` if needed |
| **web** `VITE_ALLOW_ANY_USER_WEB_DASHBOARD` | `true` if testing donor-on-web | omit | `true` |

Restart Node services after `.env` changes. Restart `npm run dev` (or redeploy static site) after `VITE_*` changes.

---

## What each flag does

| Variable | Service | Effect |
|----------|---------|--------|
| `ALLOW_DEV_TOKEN_MINT` | user-service | Enables `POST /v1/auth/token` (dev coordinator/donor JWT mint). |
| `VITE_ALLOW_DEV_SIGN_IN` | web (build-time) | Shows **Dev sign in** form. Requires `ALLOW_DEV_TOKEN_MINT` on user-service. |
| `ALLOW_WEB_DASHBOARD_ANY_USER` | user-service | Web `client_type: web` may sign in **donor** Google accounts and mint **coordinator** JWT (dashboard lists all intents). |
| `VITE_ALLOW_ANY_USER_WEB_DASHBOARD` | web (build-time) | MVP sign-in copy only; **must** pair with `ALLOW_WEB_DASHBOARD_ANY_USER` on user-service. |
| `DEPLOYMENT_ENV` | user-service | `production` \| `staging` \| `development` — controls production guard (below). |

Normal production web: coordinators only (`coordinator` in `user_roles`). See [coordinator-seed.sql](./coordinator-seed.sql), [web-client.md](./web-client.md).

---

## Production guard (code)

Enforced in **user-service only**. If production, these are **forced off** even when env says `true`:

- `ALLOW_DEV_TOKEN_MINT`
- `ALLOW_WEB_DASHBOARD_ANY_USER`

**Treated as production when:**

- `DEPLOYMENT_ENV=production`, or
- `NODE_ENV=production` and `RENDER=true` (default on Render)

**Staging MVP:** set `DEPLOYMENT_ENV=staging` on user-service and set unlock flags as needed. Web flags are UI-only; security is always on user-service.

---

## Local quick setup (donor-on-web MVP)

**user-service** `.env`:

```env
ALLOW_DEV_TOKEN_MINT=true
ALLOW_WEB_DASHBOARD_ANY_USER=true
```

**web** `.env`:

```env
VITE_ALLOW_ANY_USER_WEB_DASHBOARD=true
# optional:
# VITE_ALLOW_DEV_SIGN_IN=true
```

Copy from `sharingbridge-web-app/env.localtest` for a full local profile.

---

## Render production checklist

Do **not** set unlock flags on production Render services. Blueprint sets `DEPLOYMENT_ENV=production` on user-service.

| Service | Set |
|---------|-----|
| user-service | `ALLOW_DEV_TOKEN_MINT=false` (or omit), no `ALLOW_WEB_DASHBOARD_ANY_USER`, `DEPLOYMENT_ENV=production` |
| web static site | No `VITE_ALLOW_DEV_SIGN_IN`, no `VITE_ALLOW_ANY_USER_WEB_DASHBOARD` |

Standard deploy env for all services: [backend-render.md](./backend-render.md), [e2e-deployment-sequence.md](./e2e-deployment-sequence.md).
