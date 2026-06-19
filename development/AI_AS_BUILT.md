# AI — as-built wiring

**Purpose:** How AI is **wired today** (not a future plan). Phased roadmap and provider split: [AI_PLAN.md](./AI_PLAN.md). Progress snapshot: [STATUS.md](./STATUS.md) § AI.

**Last updated:** June 2026

---

## Short answer

**Yes — AI is wired end-to-end** when orchestration is running and integration flags are enabled (defaults in `sharingbridge-integration-service/env.example`):

- `AI_SUGGEST_VENDORS_ENABLED=true`
- `AI_INSTRUCTION_PACK_ENABLED=true`
- `AI_ORCHESTRATION_BASE_URL` → `sharingbridge-ai-orchestration`

| Mode | Behavior |
|------|----------|
| **`AI_LLM_MODE=deterministic`** (orchestration) | Ranked mock / template responses — used in CI and offline dev |
| **`AI_LLM_MODE=live`** + Groq + Gemini keys | Live text (Groq) and vision (Gemini) for instruction-pack |
| Flags off or orchestration unreachable | Integration may return mock (dev) or **503** when `AI_MOCK_FALLBACK_ENABLED=false` (production default) |

Clients **never** call model APIs directly. Flow: **mobile/web → integration-service → ai-orchestration → Groq/Gemini**.

---

## Architecture

```text
sharingbridge-mobile-app / sharingbridge-web-app
              │
              ▼
   sharingbridge-integration-service  (Experience API)
              │  AI_ORCHESTRATION_BASE_URL
              ▼
   sharingbridge-ai-orchestration  (FastAPI)
              ├── Groq  (text: suggest-vendors, instruction compose)
              ├── Gemini (vision: reference photo → descriptions)
              └── Nominatim (geocode for locality_key)
              │
   sharingbridge-photo-service  (reference upload — separate HTTP from mobile)
```

**Not used:** LangChain in shipped code (direct HTTP/SDK). **Deferred:** `sharingbridge-location-safety` (archived).

Public integration endpoints:

- `POST /v1/donor-setup/suggest-vendors`
- `POST /v1/donor-seeker/instruction-pack`

Orchestration exposes matching internal routes; see `sharingbridge-ai-orchestration/app/main.py`.

---

## Environment (minimum)

**integration-service:**

```env
AI_ORCHESTRATION_BASE_URL=http://localhost:8091
AI_ORCHESTRATION_INTERNAL_API_KEY=<shared secret>
AI_SUGGEST_VENDORS_ENABLED=true
AI_INSTRUCTION_PACK_ENABLED=true
```

**ai-orchestration:**

```env
AI_LLM_MODE=live          # or deterministic
GROQ_API_KEY=
GEMINI_API_KEY=
PHOTO_SERVICE_BASE_URL=http://localhost:8092
NOMINATIM_USER_AGENT=SharingBridge-Local/1.0 (you@example.com)
```

Step-by-step keys and Render: [ai-setup-handhold.md](../configuration/ai-setup-handhold.md) · [ai-orchestration-local.md](../configuration/ai-orchestration-local.md).

---

## Still open (not “unwired”)

| Item | Status |
|------|--------|
| Delivery photo + face match | Not built (photo-service upload only) |
| LangChain / LangServe | Not used; direct SDK |
| LangSmith tracing | Optional, not required for MVP |

Future phases: [AI_PLAN.md](./AI_PLAN.md).

---

## Related docs

| Doc | Use |
|-----|-----|
| [AI_PLAN.md](./AI_PLAN.md) | Provider split, future phases |
| [Donor_Setup_AI_Search_Sequence.md](../design/Donor_Setup_AI_Search_Sequence.md) | suggest-vendors sequence |
| [field-handoff.md](../configuration/field-handoff.md) | Help a seeker flow |
| [MANUAL_TESTING_GUIDE.md](../testing/MANUAL_TESTING_GUIDE.md) | §2a orchestration smoke |
