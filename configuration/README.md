# SharingBridge configuration — start here

**One place to orient yourself.** This folder is **how to run and wire** the MVP (product design — see [README.md § Documentation guide](../README.md#documentation-guide)).

| Your goal | Follow this path |
|-----------|------------------|
| **Which doc to read (full map)** | [README.md § Documentation guide](../README.md#documentation-guide) |
| **First-time setup (recommended)** | [e2e-deployment-sequence.md](./e2e-deployment-sequence.md) — Phases **0 → 5** in order |
| **Database SQL in correct order** | [database-setup-sequence.md](./database-setup-sequence.md) |
| **Local only (laptop)** | Phase 0–1 in [e2e-deployment-sequence.md](./e2e-deployment-sequence.md) → [MANUAL_TESTING_GUIDE.md](../testing/MANUAL_TESTING_GUIDE.md) §3 (mobile) / §4 (web) |
| **Deploy to Render** | [e2e-deployment-sequence.md](./e2e-deployment-sequence.md) Phases **2–5** → [backend-render.md](./backend-render.md) for env keys per service |
| **Google OAuth / coordinator seed** | [google-auth-setup.md](./google-auth-setup.md) |
| **All env vars (every service)** | [environment-variables.md](./environment-variables.md) |
| **Troubleshoot sign-in / CORS / roles** | [authentication.md](./authentication.md) + [google-auth-setup.md](./google-auth-setup.md) |

**Per-repo env:** copy each repo’s `env.example` → `.env` (gitignored). Full index: [environment-variables.md](./environment-variables.md).

---

## Roadmap (order of operations)

Use **[e2e-deployment-sequence.md](./e2e-deployment-sequence.md)** for full commands and checkpoints. Summary:

```text
Phase 0   Google Cloud (OAuth client + test users)
    ↓
Phase 1   Local Postgres + .env on user-service & integration-service
    ↓     Google sign-in on http://localhost:5173 (web) + mobile
Phase 2   Render: user-service → integration-service (+ photo-service if needed)
    ↓
Phase 3   Render: static web app (VITE_* build env)
    ↓
Phase 4   Add live site URL to Google origins + WEB_CORS_ORIGINS on both backends
    ↓
Phase 5   Verify hosted coordinator dashboard + payee flow on same API host
```

Optional branches (any time after Phase 1):

- **Photos:** [photo-service-local.md](./photo-service-local.md)
- **AI suggestions:** [ai-orchestration-local.md](./ai-orchestration-local.md)
- **Live AI keys (Groq, Gemini, Nominatim):** [ai-setup-handhold.md](./ai-setup-handhold.md)
- **Field flow (BRD):** [field-handoff.md](./field-handoff.md)

---

## Doc sitemap (what to open when)

| When you need… | Document |
|----------------|----------|
| **Step-by-step deploy order** | [e2e-deployment-sequence.md](./e2e-deployment-sequence.md) |
| **All env vars by service** | [environment-variables.md](./environment-variables.md) |
| **Render deploy (blueprint, CORS)** | [backend-render.md](./backend-render.md) |
| **Supabase / Postgres / schema** | [database-setup-sequence.md](./database-setup-sequence.md) · [database.md](./database.md) · [schema.sql](./schema.sql) |
| **Auth, JWT, roles, 403 errors** | [authentication.md](./authentication.md) |
| **All environment variables** | [environment-variables.md](./environment-variables.md) |
| **Google Console clicks** | [google-auth-setup.md](./google-auth-setup.md) |
| **Web dashboard (Vite, CORS)** | [web-client.md](./web-client.md) |
| **Mobile URLs (emulator, phone, Wi‑Fi)** | [mobile-client.md](./mobile-client.md) |
| **Manual test scripts** | [MANUAL_TESTING_GUIDE.md](../testing/MANUAL_TESTING_GUIDE.md) |
| **Product roadmap (authoritative)** | [PRODUCT_ROADMAP.md](../development/PRODUCT_ROADMAP.md) |
| **Order-ops supplement (A–B)** | [Future_Extensions.md](../design/Future_Extensions.md) |
| **Agent / development docs** | [README.md](../README.md#documentation-guide) · [AGENT_HANDOFF.md](../development/AGENT_HANDOFF.md) |

---

## Local stack (quick checklist)

Copy each repo’s `env.example` → `.env`. **All keys and local defaults:** [environment-variables.md](./environment-variables.md) (§ per service + § Local stack defaults). Mobile uses `--dart-define` — [mobile-client.md](./mobile-client.md).

Restart Node after `.env` changes. Restart `npm run dev` after web `VITE_*` changes.

---

## Render (quick checklist)

Follow [e2e-deployment-sequence.md](./e2e-deployment-sequence.md) Phases 2–5.

1. Supabase + `DATABASE_URL` on Node services — [database.md](./database.md)
2. Deploy user-service → integration-service (shared `AUTH_TOKEN_SECRET`) — [backend-render.md](./backend-render.md)
3. Static site `VITE_*` — [web-client.md](./web-client.md)
4. `WEB_CORS_ORIGINS` on **both** backends = static site `https://…onrender.com`
5. Mobile uses **same** integration host as `VITE_API_BASE_URL` — [mobile-client.md](./mobile-client.md)

**Testing:** [MANUAL_TESTING_GUIDE.md](../testing/MANUAL_TESTING_GUIDE.md) — mobile **§3**, web **§4**.
