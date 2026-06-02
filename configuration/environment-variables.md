# Environment variables (dev unlocks & MVP web access)

**Single reference** for optional flags. Per-repo: `env.example` → `.env` (gitignored).

| | Local dev | Render production | Render staging |
|--|-----------|-------------------|----------------|
| **user-service** `BYPASS_GOOGLE_SIGN_IN` | `true` to skip Google | omit / `false` | `true` if needed |
| **user-service** `ALLOW_WEB_DASHBOARD_ANY_USER` | `true` for donor-on-web MVP | omit / `false` | `true` |
| **user-service** `DEPLOYMENT_ENV` | omit or `development` | `production` | `staging` |
| **web** `VITE_BYPASS_GOOGLE_SIGN_IN` | `true` to show bypass form | omit | `true` if needed |
| **web** `VITE_ALLOW_ANY_USER_WEB_DASHBOARD` | `true` for donor-on-web MVP copy | omit | `true` |

Restart Node after `.env` changes. Restart `npm run dev` (or redeploy static site) after `VITE_*` changes.

---

## What each flag does

| Variable | Service | Effect |
|----------|---------|--------|
| `BYPASS_GOOGLE_SIGN_IN` | user-service | **Sign in without Google** — `POST /v1/auth/token` with a user id → JWT. |
| `VITE_BYPASS_GOOGLE_SIGN_IN` | web (build-time) | Shows the bypass form. Requires `BYPASS_GOOGLE_SIGN_IN` on user-service. |
| `ALLOW_WEB_DASHBOARD_ANY_USER` | user-service | **Google** web sign-in: donors get coordinator JWT. Independent of bypass. |
| `VITE_ALLOW_ANY_USER_WEB_DASHBOARD` | web (build-time) | MVP sign-in copy; pairs with `ALLOW_WEB_DASHBOARD_ANY_USER`. |
| `DEPLOYMENT_ENV` | user-service | `production` \| `staging` \| `development` — production guard (below). |

---

## Production guard (code)

Enforced in **user-service only**. Bypass and MVP flags are **forced off** in production:

- `BYPASS_GOOGLE_SIGN_IN`
- `ALLOW_WEB_DASHBOARD_ANY_USER`

Production when `DEPLOYMENT_ENV=production`, or `NODE_ENV=production` on Render (`RENDER=true`).

**Staging:** `DEPLOYMENT_ENV=staging` on user-service.

---

## Local quick setup

### Skip Google (typed user id)

**user-service** `.env`:

```env
BYPASS_GOOGLE_SIGN_IN=true
```

**web** `.env`:

```env
VITE_BYPASS_GOOGLE_SIGN_IN=true
```

### Donor-on-web MVP (Google only)

**user-service:** `ALLOW_WEB_DASHBOARD_ANY_USER=true`  
**web:** `VITE_ALLOW_ANY_USER_WEB_DASHBOARD=true`  
Does **not** require bypass flags.

---

## Render production

| Service | Set |
|---------|-----|
| user-service | No `BYPASS_GOOGLE_SIGN_IN`, no `ALLOW_WEB_DASHBOARD_ANY_USER`, `DEPLOYMENT_ENV=production` |
| web | No `VITE_BYPASS_GOOGLE_SIGN_IN`, no `VITE_ALLOW_ANY_USER_WEB_DASHBOARD` |

See [backend-render.md](./backend-render.md), [e2e-deployment-sequence.md](./e2e-deployment-sequence.md).
