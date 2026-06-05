# AI Platform Integration — Technical Plan

**Status:** Deterministic MVP shipped (`sharingbridge-ai-orchestration` + integration bridge); live LLM (`AI_LLM_MODE=openai`) not wired yet  
**Full phased plan (presets, image/location text, seeker ID, LangChain vs direct LLM):** [AI_IMPLEMENTATION_PLAN.md](./AI_IMPLEMENTATION_PLAN.md)  
**Related:** [IMPLEMENTATION_APPROACH.md](./IMPLEMENTATION_APPROACH.md) (AI interactions slice), [SharingBridge_End_to_End_Workflow.md](../design/SharingBridge_End_to_End_Workflow.md), [Technical Architecture](../design/SharingBridge_Technical_Architecture.md) (Hybrid AI Strategy)

---

## Short answer: is AI implemented in the app today?

**No.** Real AI/ML pipelines are **not** wired end-to-end. What exists:

| Capability | Shipped in code? | Where |
|------------|-----------------|--------|
| Donor setup vendor suggestions | **Orchestration when flagged** | integration → ai-orchestration (deterministic ranking); mock fallback |
| Delivery instruction pack | **API + fallback** | `POST /v1/donor-seeker/instruction-pack`; mobile stub if unreachable |
| Handover guidance (BRD step 4) | **Shipped** | `sharingbridge-mobile-app` — fixed **Quick guidance** copy |
| Locality safety scoring | **Deferred / archived** | `sharingbridge-location-safety` — not MVP; repo archived |
| Photo upload, face embeddings, match | **Not built** | Planned → `sharingbridge-photo-service` (README only) |
| LLM orchestration (LangChain or equivalent) | **Deterministic service built**; live LLM pending | `sharingbridge-ai-orchestration` |

Mobile and backend **must not** call OpenAI/Anthropic (or similar) directly from the client. All model access goes through **backend AI modules** behind authenticated APIs.

---

## What the docs already say (and what is missing)

| Topic | Covered in existing docs? |
|-------|---------------------------|
| *That* AI should generate instructions / descriptions | Yes — BRD step 6, Technical Architecture “Hybrid AI Strategy” |
| Fixed **handover guidance** (BRD step 4) | Yes — mobile Offer food help; geo safety **deferred** |
| **Photo** storage + embeddings + match | Yes — photo-service bootstrap §9, architecture §3.3 |
| **LangChain** (or similar) setup on a host | **No** — until this doc |
| Prompt chains, structured JSON, retries, fallbacks | Partially — Donor Setup sequence assumes external AI; no runtime |
| Bridging **mobile → integration → AI platform → model APIs** | **No** — until this doc |
| Secrets, env, cost guards, observability for AI calls | Partially — generic Render/env notes only |

---

## Target architecture (bridge pattern)

Clients talk only to **`sharingbridge-integration-service`** (the **Experience API** / shared BFF). Integration HTTP-calls the **AI orchestration** service, which runs **direct Groq/Gemini pipelines** (LangChain was considered; not used in shipped MVP). Handover guidance (BRD step 4) is **in-app copy only** — not a backend service in MVP.

Terminology: [Technical Architecture § As-built](../design/SharingBridge_Technical_Architecture.md#as-built-architecture-june-2026).

```mermaid
flowchart TB
  subgraph clients["Clients"]
    M[sharingbridge-mobile-app]
    W[sharingbridge-web-app]
  end

  subgraph edge["API edge"]
    G[sharingbridge-api-gateway\noptional MVP: call integration directly]
  end

  subgraph core["Core backend"]
    I[sharingbridge-integration-service\ninstruction-pack owner\nsuggest-vendors]
    O[sharingbridge-order-service]
    U[sharingbridge-user-service]
  end

  subgraph ai["AI modules"]
    AIO[sharingbridge-ai-orchestration\nLangChain / LangServe\nprompts + structured output]
    PHO[sharingbridge-photo-service\nupload + embeddings + match]
  end

  subgraph external["External providers"]
    LLM[Model APIs\nOpenAI / Anthropic / Azure OpenAI / local Ollama dev]
    STORE[Cloudinary / S3\nphoto blobs]
  end

  M --> G
  W --> G
  G --> I
  G --> O
  G --> U
  I --> AIO
  I --> PHO
  AIO --> LLM
  AIO --> PHO
  PHO --> STORE
  PHO --> LLM
```

**MVP simplification:** Collapse gateway until needed; **integration-service** HTTP-calls **ai-orchestration** on the same Render/Railway account or as a second service. Do **not** embed LangChain inside the Flutter app.

---

## AI capabilities → services → orchestration

| Product capability | Owning API (donor-facing) | AI module | Model / technique |
|--------------------|---------------------------|-----------|------------------|
| Donor setup: vendor/menu suggestions | `POST /v1/donor-setup/suggest-vendors` (integration) | Orchestration chain | LLM + strict JSON schema; location in prompt |
| Instruction pack + dignity filter | `POST /v1/donor-seeker/instruction-pack` (integration) | Orchestration chain | LLM + template merge; optional vision on reference photo |
| Beneficiary verbal notes sanitization | Same | Orchestration sub-chain | LLM policy pass |
| Handover guidance | Mobile **Offer food help** step 1 | **No backend** | Fixed copy; donor judgment |
| Reference photo storage | `POST /v1/photos/upload` (photo-service) | Storage pipeline | S3/Cloudinary |
| Face embedding + donor↔delivery match | photo-service + order events | CV pipeline | Embedding model (e.g. FaceNet-class); not necessarily LLM |
| Assistance history hint (optional) | order / photo-service | Embedding similarity | Architecture §3.3 |

**LangChain role:** Orchestrate **LLM** flows only (suggest-vendors, instruction-pack, text sanitization). Use **dedicated services** for safety rules and computer vision—not every path needs LangChain.

---

## Proposed repo: `sharingbridge-ai-orchestration`

New service (**shipped** deterministic MVP; live LLM pending). Add **photo-service** next; **location-safety** deferred/archived.

**Responsibilities:**

- Versioned **prompt templates** and **output JSON schemas**
- LangChain (or equivalent) chains: retrieve context → call LLM → validate → retry/fallback
- **No** donor auth logic (trust `integration-service` service-to-service token or internal network)
- Expose **internal** HTTP only (not public internet without gateway)

**Suggested endpoints (internal):**

```
POST /internal/v1/llm/suggest-vendors
POST /internal/v1/llm/instruction-pack
POST /internal/v1/llm/sanitize-text
GET  /health
```

Integration-service maps public routes to these internal calls and attaches `user_id`, request-id, and audit metadata.

---

## Hosting the AI modules (platform setup)

Align with [IMPLEMENTATION_APPROACH.md](./IMPLEMENTATION_APPROACH.md) free tier (Render/Railway) for MVP; model keys in dashboard env vars (secrets manager deferred). **Render deploy:** [configuration/backend-render.md](../configuration/backend-render.md).

### Option A — Recommended MVP

| Deployable | Host | Notes |
|------------|------|--------|
| `sharingbridge-ai-orchestration` | Render / Railway web service | Python (FastAPI) + LangChain; `PORT`, health check |
| `sharingbridge-location-safety` | **Archived** — do not implement for MVP | — |
| `sharingbridge-photo-service` | Same or separate service | Upload + embedding worker |
| Model APIs | Vendor cloud | OpenAI / Anthropic / Azure OpenAI |
| LangSmith (optional) | LangChain SaaS | Tracing, evals — dev/staging |

### Option B — LangServe on managed host

Package orchestration as **LangServe** app (FastAPI) deployed like any other backend service. Integration-service calls `https://ai-orchestration-<env>.onrender.com/...`.

### Option C — Local dev

- **Ollama** or **LM Studio** for offline LLM via LangChain `ChatOllama` base URL
- `AI_LLM_BASE_URL=http://localhost:11434` in orchestration `.env`
- Mobile still uses integration-service on `localhost:8080` — never Ollama directly

### Environment variables (orchestration service)

```bash
# Model provider (pick one for MVP)
OPENAI_API_KEY=
# or ANTHROPIC_API_KEY= / AZURE_OPENAI_ENDPOINT= + AZURE_OPENAI_KEY=

AI_LLM_MODEL=gpt-4o-mini          # cost-conscious default
AI_LLM_TIMEOUT_MS=30000
AI_LLM_MAX_RETRIES=2

# Internal service URLs (called by orchestration)
PHOTO_SERVICE_BASE_URL=http://localhost:8092
AI_SAFETY_BASE_URL=http://localhost:8093

# Optional
LANGCHAIN_TRACING_V2=true
LANGCHAIN_API_KEY=                  # LangSmith
LANGCHAIN_PROJECT=sharingbridge-dev
```

Integration-service additionally needs:

```bash
AI_ORCHESTRATION_BASE_URL=http://localhost:8091
AI_ORCHESTRATION_INTERNAL_API_KEY=   # static service API key (integration → AI only)
```

---

## Bridge: mobile ↔ backend ↔ AI (sequence)

**Donor setup — suggest vendors (target):**

```mermaid
sequenceDiagram
  participant M as Mobile app
  participant I as Integration service
  participant A as AI orchestration
  participant L as LLM provider

  M->>I: POST /v1/donor-setup/suggest-vendors\n(Bearer token, query, location)
  I->>A: POST /internal/v1/llm/suggest-vendors
  A->>A: LangChain chain + JSON schema validate
  A->>L: Chat completion
  L-->>A: Raw JSON
  A-->>I: Top 5 suggestions (validated)
  I-->>M: Same contract as today
```

**Offer food help — instruction pack (target):**

```mermaid
sequenceDiagram
  participant M as Mobile app
  participant I as Integration service
  participant P as Photo service
  participant A as AI orchestration
  participant L as LLM provider

  M->>P: POST /v1/photos/upload (reference)
  P-->>M: photo_id, secure_photo_url
  M->>I: POST /v1/donor-seeker/instruction-pack\n(photo_id, geo, notes, presets)
  I->>P: GET embedding / metadata (internal)
  I->>A: POST /internal/v1/llm/instruction-pack
  A->>L: Vision + text (optional) + template fill
  L-->>A: Structured fields
  A-->>I: delivery_instructions + beneficiary_description + ...
  I-->>M: Public DTO (no raw embeddings)
```

---

## Orchestration style (LangChain vs direct LLM)

**Decision (June 2026):** Use **direct OpenAI SDK calls** and explicit Python pipeline functions for MVP live LLM. Defer LangChain until flows need RAG, multi-tool agents, or heavy branching. Details: [AI_IMPLEMENTATION_PLAN.md](./AI_IMPLEMENTATION_PLAN.md) § *LangChain vs direct LLM*.

**MVP implementation sketch (no LangChain):**

- `openai` Python SDK (or `httpx` to provider REST)
- `pydantic` response models + JSON schema / `response_format`
- Versioned prompts in `prompts/*.yaml`
- `AI_LLM_MODE=deterministic` | `openai` switch in `app/services/*.py`
- Optional **LangSmith** tracing without LangChain abstractions

**Patterns:**

1. **Structured output** — validate with Pydantic; reject malformed responses → integration mock fallback.
2. **Prompt registry** — `prompts/suggest_vendors_v1.yaml`, `prompts/instruction_pack_v1.yaml`.
3. **Retries** — transient LLM errors only; no retry on validation failures.
4. **PII** — minimize seeker identifiers in logs; redact in tracing tools.

**Not LLM / not LangChain:**

- Handover guidance (mobile fixed copy).
- Face match (photo-service CV after delivery upload).
- PostGIS neighbourhood lists (integration-service).

---

## Phased rollout

| Phase | Deliverable | Replaces |
|-------|-------------|----------|
| **0** (today) | Mocks/stubs | — |
| **1** | Deploy `ai-orchestration` skeleton + health; wire integration `suggest-vendors` to LLM behind feature flag | `MOCK_SUGGESTIONS` |
| **2** | `instruction-pack` public API + mobile HTTP client | `requestStubDeliveryInstructions` |
| **3** | Deploy photo-service; wire upload + delivery match | Local-only photo path |
| **4** | Vision in instruction chain; delivery match job | Placeholder faceprint lines |

Feature flag example: `AI_SUGGEST_VENDORS_ENABLED=true` in integration-service env.

---

## Contracts and testing

- Publish OpenAPI for **public** integration routes first (`design/contracts/`).
- Internal orchestration contracts can live in `sharingbridge-ai-orchestration/openapi/` until gateway stabilizes.
- Contract tests: integration-service → mock orchestration HTTP server (no live LLM in CI).
- Optional nightly job: live LLM smoke with `AI_LLM_SMOKE_ENABLED=1`.

---

## Security and compliance

- API keys only on server-side orchestration and specialist services.
- Mobile receives **generated text** and **opaque photo URLs**, not provider keys or embeddings.
- Align instruction-pack wording with privacy review ([IMPLEMENTATION_APPROACH](./IMPLEMENTATION_APPROACH.md) privacy checkpoints).
- Log retention policy for LangSmith / application logs before production.

---

## Checklist: bootstrap AI platform (engineering)

- [x] Create `sharingbridge-ai-orchestration` repo (FastAPI deterministic MVP + Dockerfile)
- [ ] Deploy to Render/Railway; set model API keys in dashboard
- [x] Add `AI_ORCHESTRATION_BASE_URL` to integration-service
- [x] Implement internal client in integration-service with timeout + typed errors
- [x] Replace `buildSuggestVendorsResponse` mock path behind feature flag
- [x] Implement `POST /v1/donor-seeker/instruction-pack` calling orchestration
- [x] Update mobile: HTTP client for instruction-pack (local stub fallback when API down)
- [ ] Deploy photo-service; wire IMPLEMENTATION_APPROACH phases A–D (guidance shipped on mobile; location-safety deferred)
- [ ] Add LangSmith project for dev tracing (optional)
- [ ] Document smoke steps in `testing/MANUAL_TESTING_GUIDE.md` when phase 1 ships

---

## Document map (AI-related)

| Document | Use |
|----------|-----|
| **This file** | AI hosting, LangChain, bridges, env, phases |
| [IMPLEMENTATION_APPROACH.md](./IMPLEMENTATION_APPROACH.md) | Product-facing AI interactions (4 capabilities) |
| [Donor_Setup_AI_Search_Sequence.md](../design/Donor_Setup_AI_Search_Sequence.md) | Donor setup sequence (update when orchestration ships) |
| [SharingBridge_End_to_End_Workflow.md](../design/SharingBridge_End_to_End_Workflow.md) | Full journey diagrams |
| [AGENT_HANDOFF.md](./AGENT_HANDOFF.md) | Shipped vs planned status |
