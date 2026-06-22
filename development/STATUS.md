# SharingBridge — status vs plan

**Purpose:** Single **where we are** doc, measured against [ENGINEERING_PLAN.md](./ENGINEERING_PLAN.md) (engineering plan) and [PRODUCT_MODEL.md](./PRODUCT_MODEL.md) (product vocabulary).

**Update this file** when a workstream ships or a milestone closes. Do not duplicate this table in other development docs.

| Also read | For |
|-----------|-----|
| [ENGINEERING_PLAN.md](./ENGINEERING_PLAN.md) | Long-term plan, phases E–I, free-tier stack |
| [PRODUCT_MODEL.md](./PRODUCT_MODEL.md) | Glossary, actors, initiation routes |
| [AGENT_SESSION.md](./AGENT_SESSION.md) | Agent session: next tasks, runbook, recent commits |
| [database-setup-sequence.md](../configuration/database-setup-sequence.md) | SQL **1 → M1–M5** and **Where you are** on each environment |

**Last updated:** June 2026

---

## Target model

```text
Direct order (vendor app)  +  Eco kitchen routes (pledge / I pay)
        ↓                              ↓
   Order intents                  Demand board → kitchen commit
        ↓                              ↓
   Payment off-platform         Connection (order code) + notify
        ↓                              ↓
   Delivery proof (Phase B)      Marketplace F–I (future)
```

---

## Workstream progress

| Workstream | Plan reference | Status | Notes |
|------------|----------------|--------|-------|
| **Foundation** | IMPLEMENTATION § Free tier | **Shipped** | Supabase Postgres, Render APIs, Google auth, Flutter + Vite |
| **Direct order** | field-handoff, BRD steps 4–7 | **Shipped** | Help a seeker → instruction-pack → vendor deep links |
| **Eco kitchen** | Eco_Kitchen_Initiation_Flow phases 1–6 | **Shipped** | Routes, consent, order codes, Connection, mobile I pay |
| **Marketplace E** | IMPLEMENTATION § E | **Shipped** | Actions board, pledges, kitchen commit, web Updates banner |
| **Connection notify** | Eco Kitchen phase 4 + M5 | **Code shipped** | FCM + notification-service; wire per env |
| **Marketplace F–I** | IMPLEMENTATION § F–I | **Not started** | Beneficiary profile, transport, allocation |
| **AI bridge** | AI_PLAN | **Shipped** | integration → ai-orchestration; flags on by default in `env.example` |
| **AI live models** | AI_PLAN | **Shipped** | `AI_LLM_MODE=live` + Groq/Gemini keys — [ai-setup-handhold.md](../configuration/ai-setup-handhold.md) |
| **AI delivery match** | IMPLEMENTATION phase D | **Not started** | No face embeddings / delivery verification |
| **Order ops A–B** | Future_Extensions | **Partial** | Payment-done on web; delivery proof open |
| **Transactional email** | notification-service | **Not started** | FCM only; email copy exists in webhook payload |
| **Mobile Connection UI** | Eco Kitchen | **Not started** | Web Connection + FCM nudge |

---

## Repos (as-built)

| Repo | Role | Status |
|------|------|--------|
| `sharingbridge-user-service` | Auth, presets, Postgres users | **Shipped** |
| `sharingbridge-integration-service` | Experience API / BFF | **Shipped** |
| `sharingbridge-mobile-app` | Initiator Flutter app | **Shipped** |
| `sharingbridge-web-app` | Coordinator + initiator (limited) dashboard | **Shipped** |
| `sharingbridge-ai-orchestration` | suggest-vendors, instruction-pack | **Shipped** (deterministic + live) |
| `sharingbridge-photo-service` | Reference photo upload | **Shipped** (no vision/embeddings) |
| `sharingbridge-notification-service` | FCM on kitchen commit | **Shipped** |
| `sharingbridge-api-gateway`, `order-service`, `infra` | Scale path | **Not started** |
| `sharingbridge-location-safety` | Geo scoring | **Archived** |

Key integration routes: `suggest-vendors`, `instruction-pack`, `order-intents`, `seeker-demands`, `demand/board`, `pledges`, `vendor-bids`, `connections/:orderCode`, `device-tokens`. OpenAPI: [design/contracts/README.md](../design/contracts/README.md) (initiator handoff + marketplace + donor-setup presets).

---

## AI (accurate snapshot)

| Capability | Shipped? | How |
|------------|----------|-----|
| Vendor suggestions | **Yes** | `POST /v1/donor-setup/suggest-vendors` → orchestration; mock only if flags off or orchestration down |
| Instruction pack | **Yes** | `POST /v1/donor-seeker/instruction-pack` → orchestration; mobile local stub if API unreachable |
| Live Groq + Gemini | **Yes** | `AI_LLM_MODE=live` in ai-orchestration + API keys |
| Deterministic / CI | **Yes** | `AI_LLM_MODE=deterministic` (default for offline CI) |
| Reference photo upload | **Yes** | photo-service → Cloudinary |
| Vision in instruction chain | **Yes** when live | Gemini analyzes photo URL; Groq composes text |
| Face match / delivery verify | **No** | Future phase D |

Setup: [ai-orchestration-local.md](../configuration/ai-orchestration-local.md) · [ai-setup-handhold.md](../configuration/ai-setup-handhold.md) · [AI_PLAN.md](./AI_PLAN.md) (future phases).

---

## SQL and deploy (per environment)

Code expects full schema when hosted. Progressive order:

**1** → **M1** → **M2** → **M3** → **M4** → **M5** → notification-service + `CONNECTION_NOTIFY_WEBHOOK_*` + Firebase + APK rebuild.

| Skipped | Symptom |
|---------|---------|
| M1–M3 | Actions `schema_pending` or empty menu picker |
| M4 | No `SB-…` order codes; no Connection API |
| M5 / notify deploy | No FCM; web Connection still works |

Detail: [database-setup-sequence.md](../configuration/database-setup-sequence.md) § **If a step was skipped**.

---

## Next priorities

1. **UX redesign first** (web + mobile): route/view split, less scrolling, clearer role language.
2. **Terminology cleanup** in visible UI: donor-oriented labels -> initiator vocabulary where appropriate.
3. **Mobile Connection panel** — in-app order-code lookup.
4. **Transactional email** in notification-service (Resend/SendGrid).
5. **Order ops + delivery proof** — [Future_Extensions.md](../design/Future_Extensions.md) Phase B.
6. **Kitchen/supplier onboarding + mentor tools** (transparency artifacts, policy acknowledgements, training materials).
7. **Demand forecasting**: lightweight portion trend first, detailed BOM forecast later.

Session backlog and commit log: [AGENT_SESSION.md](./AGENT_SESSION.md).

Roadmap details: [Experience_Redesign_and_Onboarding_Roadmap.md](../design/Experience_Redesign_and_Onboarding_Roadmap.md).

---

## Verification

| Check | Doc |
|-------|-----|
| Manual E2E | [MANUAL_TESTING_GUIDE.md](../testing/MANUAL_TESTING_GUIDE.md) |
| BRD journey ✅ / 🟡 / ⬜ | [SharingBridge_End_to_End_Workflow.md](../design/SharingBridge_End_to_End_Workflow.md) |
| Eco kitchen phases | [Eco_Kitchen_Initiation_Flow.md](../design/Eco_Kitchen_Initiation_Flow.md) § 10 |
