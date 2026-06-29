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
Phase 2   Render: user-service → ai-orchestration → integration-service → photo-service → notification-service
    ↓     CONNECTION_NOTIFY_WEBHOOK_* on integration · Firebase · M5 · rebuilt APK
    ↓
Phase 3   Render: static web app (VITE_* build env)
    ↓
Phase 4   Add live site URL to Google origins + WEB_CORS_ORIGINS on both backends
    ↓
Phase 5   Verify hosted coordinator dashboard + initiator flow on same API host
```

Optional branches (any time after Phase 1):

- **Photos:** [photo-service-local.md](./photo-service-local.md)
- **AI suggestions:** [ai-orchestration-local.md](./ai-orchestration-local.md)
- **Live AI keys (Groq, Gemini, Nominatim):** [ai-setup-handhold.md](./ai-setup-handhold.md)
- **Field flow (BRD):** [field-handoff.md](./field-handoff.md)
- **Handover location (steps 10–13):** [field-handoff.md](./field-handoff.md) → [Location_Services_Vendor_Abstraction.md](../design/Location_Services_Vendor_Abstraction.md) → [Handover_Location_Map_Picker.md](../design/Handover_Location_Map_Picker.md) → [mobile-client.md § Handover](./mobile-client.md#handover-location--map-picker-address-pickup-note) — full index: [README.md § Documentation guide](../README.md#documentation-guide)

---

## Doc sitemap (what to open when)

| When you need… | Document |
|----------------|----------|
| **Step-by-step deploy order** | [e2e-deployment-sequence.md](./e2e-deployment-sequence.md) |
| **All env vars by service** | [environment-variables.md](./environment-variables.md) |
| **Render deploy (blueprint, CORS)** | [backend-render.md](./backend-render.md) |
| **FCM / notification-service** | [notification-service-local.md](./notification-service-local.md) |
| **Supabase / Postgres / schema** | [database-setup-sequence.md](./database-setup-sequence.md) · [database.md](./database.md) · [schema-spatial-bootstrap.sql](./schema-spatial-bootstrap.sql) · [schema.sql](./schema.sql) |
| **Auth, JWT, roles, 403 errors** | [authentication.md](./authentication.md) |
| **All environment variables** | [environment-variables.md](./environment-variables.md) |
| **Google Console clicks** | [google-auth-setup.md](./google-auth-setup.md) |
| **Web dashboard (Vite, CORS)** | [web-client.md](./web-client.md) |
| **Mobile URLs (emulator, phone, Wi‑Fi)** | [mobile-client.md](./mobile-client.md) |
| **Handover location (read in order)** | [field-handoff.md](./field-handoff.md) → [Location_Services_Vendor_Abstraction.md](../design/Location_Services_Vendor_Abstraction.md) → [Handover_Location_Map_Picker.md](../design/Handover_Location_Map_Picker.md) → [mobile-client.md § Handover](./mobile-client.md#handover-location--map-picker-address-pickup-note) |
| **Full doc index & reading order** | [README.md § Documentation guide](../README.md#documentation-guide) |
| **Manual test scripts** | [MANUAL_TESTING_GUIDE.md](../testing/MANUAL_TESTING_GUIDE.md) — **§4d–4g** (Actions, Connection, FCM) |
| **Product model (authoritative)** | [PRODUCT_MODEL.md](../development/PRODUCT_MODEL.md) |
| **Order-ops supplement (A–B)** | [Future_Extensions.md](../design/Future_Extensions.md) |
| **Agent / development docs** | [README.md](../README.md#documentation-guide) · [AGENT_SESSION.md](../development/AGENT_SESSION.md) |

---

## Local stack (quick checklist)

Copy each repo’s `env.example` → `.env`. **All keys and local defaults:** [environment-variables.md](./environment-variables.md) (§ per service + § Local stack defaults). Mobile uses `--dart-define` — [mobile-client.md](./mobile-client.md).

Restart Node after `.env` changes. Restart `npm run dev` after web `VITE_*` changes.

---

## Render (quick checklist)

Follow [e2e-deployment-sequence.md](./e2e-deployment-sequence.md) Phases 2–5.

1. Supabase + **1 → M1–M5** — [database-setup-sequence.md](./database-setup-sequence.md)
2. Deploy user-service → integration-service → photo-service → notification-service (shared `AUTH_TOKEN_SECRET`) — [backend-render.md](./backend-render.md)
3. Wire `CONNECTION_NOTIFY_WEBHOOK_*` on integration — [notification-service-local.md](./notification-service-local.md)
4. Static site `VITE_*` — [web-client.md](./web-client.md)
5. `WEB_CORS_ORIGINS` on **both** backends = static site `https://…onrender.com`
6. Mobile uses **same** integration host as `VITE_API_BASE_URL`; rebuild APK with `google-services.json` — [mobile-client.md](./mobile-client.md). Optional handover map: `GOOGLE_MAPS_API_KEY` in `android/local.properties` ([Handover_Location_Map_Picker.md](../design/Handover_Location_Map_Picker.md)).

**Testing:** [MANUAL_TESTING_GUIDE.md](../testing/MANUAL_TESTING_GUIDE.md) — mobile **§3**, web **§4d–4g**.
