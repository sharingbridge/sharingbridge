# AI implementation plan

**Status:** Active plan (June 2026)  
**Audience:** Engineering and product  
**Related:** [AI_PLATFORM_INTEGRATION.md](./AI_PLATFORM_INTEGRATION.md) (hosting, env, bridges), [Donor_Setup_AI_Search_Sequence.md](../design/Donor_Setup_AI_Search_Sequence.md), [field-handoff.md](../configuration/field-handoff.md)

This document is the **full phased plan** for SharingBridge AI: preset collection, image/location descriptions, and seeker identification. It also answers **LangChain vs direct LLM** for this codebase.

---

## What is shipped today

| Piece | State |
|-------|--------|
| `sharingbridge-ai-orchestration` | FastAPI service; **`AI_LLM_MODE=deterministic`** (no live model) |
| Integration flags | `AI_SUGGEST_VENDORS_ENABLED`, `AI_INSTRUCTION_PACK_ENABLED` + `AI_ORCHESTRATION_BASE_URL` |
| Mobile **Vendor presets** | `POST /v1/donor-setup/suggest-vendors` → orchestration or mock fallback |
| Mobile **Help a seeker** | Photo upload → `POST /v1/donor-seeker/instruction-pack`; **GPS captured before instruction-pack** (not only on copy) |
| `sharingbridge-photo-service` | Reference photo upload + JWT; **no vision/embeddings yet** |
| Live OpenAI / LangChain | **Not wired** — `OPENAI_API_KEY` and `AI_LLM_MODE=openai` exist in config only |

---

## Three product goals

### 1) AI for collecting presets (donor setup)

**User story:** Donor types free text (app, restaurant, menu hints); app uses location when available; API returns up to five confirmable presets with deep links.

**Flow:** Mobile → `POST /v1/donor-setup/suggest-vendors` → integration → `POST /internal/v1/llm/suggest-vendors` → donor confirms → `POST /v1/donor-setup/preferences`.

**Outputs (strict JSON):**

```json
{
  "suggestions": [
    {
      "restaurant_name": "string",
      "app_name": "string",
      "menu_items": ["string"],
      "order_url": "https://...",
      "confidence": 0.0
    }
  ]
}
```

**Acceptance:** Suggestions respect `query_text` + optional `lat`/`lng`/`manual_area`; invalid JSON → integration mock fallback; no client-side API keys.

---

### 2) Image description and location description (Help a seeker)

**User story:** When the donor generates delivery instructions, the courier text includes human-readable **where** and **who to look for** (appearance only), not only raw coordinates.

| Field | How produced | Stored |
|-------|----------------|--------|
| **`location_description`** | Reverse geocode (Nominatim or Maps API) + optional one-line LLM polish from `lat`/`lng`/`location_label` | Order intent `payload` and/or columns |
| **`image_description`** | Vision model on reference thumbnail URL (consent-based photo) | Same |
| **`delivery_instructions`** | Template + LLM merge of presets, notes, descriptions, program copy | Returned to mobile; copied to clipboard |

**Inputs already available:** `lat`/`lng` from mobile at instruction generation, `reference_photo_artifact_id`, `verbal_handover_notes`, saved presets.

**Policy:** No named identification claims from vision (“this is Raj”); no medical/legal assertions; run existing `sanitize_handover_notes` on all generated text.

---

### 3) Locating and identifying the seeker

Split into two layers — different technology and privacy review.

**A — Soft identification (LLM, Phase 2–3)**  
Combine `image_description`, `location_description`, donor notes, and preset context into **`seeker_handover_hints`** for couriers. Non-definitive, consent-based wording.

**B — Hard identification (CV, Phase 5)**  
- On `seeker_reference` upload: face embedding in **photo-service** (not LLM).  
- On delivery acknowledgement photo: similarity score vs reference.  
- Internal route e.g. `POST /internal/v1/cv/seeker-match`.  
- Requires explicit privacy review before production.

---

## LangChain vs direct LLM — recommendation

### Short answer

**Use direct LLM calls (OpenAI SDK or equivalent) with explicit Python pipeline steps.**  
Do **not** introduce LangChain for the MVP live model path. Revisit LangChain (or LangSmith-only tracing) when flows become multi-tool, retrieval-heavy, or branchy.

### Why direct LLM fits SharingBridge now

| Factor | This project | Implication |
|--------|----------------|-------------|
| Number of flows | 2 main LLM surfaces (suggest-vendors, instruction-pack) + 1–2 sub-steps (geocode, vision) | Linear pipelines, not agents |
| Output shape | Fixed JSON / fixed narrative sections | `response_format` / Pydantic validation is enough |
| Latency & cost | Mobile user waiting on one button | Fewer hops = fewer tokens and failures |
| Existing code | Deterministic builders in `app/services/*.py` | Swap “deterministic” for “call OpenAI” behind `AI_LLM_MODE` |
| CI | Must not require live API keys | Mock LLM client in tests; deterministic mode stays default |

### What LangChain is good for (later)

- **RAG** over donor history, vendor catalogs, or policy docs  
- **Multi-tool agents** (search web, call maps, call DB, then summarize)  
- **Complex retry / branch graphs** with LangSmith evals in staging  
- **Many prompt versions** with shared memory/chains across 5+ endpoints  

None of these are required for the first live LLM release.

### Recommended orchestration pattern (no LangChain)

Treat each endpoint as a **plain async pipeline** in `sharingbridge-ai-orchestration`:

```text
instruction_pack(payload):
  1. sanitize_notes(payload)           # rules, no LLM
  2. location_description = geocode(payload.lat, payload.lng)  # HTTP API
  3. image_description = vision(photo_url) if photo           # 1 LLM call
  4. delivery_instructions = llm_compose(...)               # 1 LLM call OR template
  5. validate(InstructionPackResponse)                      # Pydantic
  6. return JSON
```

```text
suggest_vendors(payload):
  1. build_prompt(query, location context)
  2. llm_structured_json(SuggestVendorsResponse)              # 1 LLM call
  3. enrich_urls / clamp to 5
  4. return JSON
```

**Optional:** LangSmith (or OpenTelemetry) for trace IDs **without** LangChain abstractions.

### What not to put in LangChain

- Face embedding and donor↔delivery match (**photo-service**, CV model)  
- PostGIS neighbourhood queries (**integration-service**)  
- JWT auth and photo upload (**integration / photo-service**)

---

## Implementation phases

| Phase | ID | Deliverable | LLM? | Repo(s) |
|-------|-----|-------------|------|---------|
| **0** | — | Deterministic orchestration + integration flags + mobile HTTP | No | Done |
| **1** | AI-1 | Live **suggest-vendors** (`AI_LLM_MODE=openai`) | 1 structured call | ai-orchestration, integration env |
| **2** | AI-2 | **location_description** in instruction-pack (geocode + optional polish) | 0–1 call | ai-orchestration |
| **3** | AI-3 | **image_description** (vision on signed photo URL) | 1 vision call | ai-orchestration, photo-service URL |
| **4** | AI-4 | Persist descriptions on order intent; show on web detail | No | integration, web-app |
| **5** | AI-5 | **seeker_handover_hints** merged into instruction-pack | 1 compose call | ai-orchestration |
| **6** | AI-6 | Face embedding + delivery match | CV, not LLM | photo-service |

### Phase AI-1 — Presets (first live LLM)

**Code:**

- `app/llm/openai_client.py` — chat completions + JSON schema / `response_format`  
- `app/services/suggest_vendors.py` — branch on `settings.llm_mode`  
- `prompts/suggest_vendors_v1.yaml` — versioned prompt  
- Tests: mock OpenAI; CI keeps `deterministic`  

**Deploy:**

- Render: `OPENAI_API_KEY`, `AI_LLM_MODE=openai` on ai-orchestration  
- Integration: `AI_ORCHESTRATION_BASE_URL`, `AI_SUGGEST_VENDORS_ENABLED=true`  

**Done when:** Donor setup search returns LLM-ranked vendors in staging; fallback still works if orchestration is down.

---

### Phase AI-2 — Location description

**Code:**

- `app/geo/reverse_geocode.py` — Nominatim (dev) or Google Geocoding (prod)  
- Add `location_description` to `InstructionPackResponse` schema  
- Integration forwards field; mobile unchanged (already sends `lat`/`lng`)  

**Done when:** Instruction text includes a readable place line, not only `12.94, 80.24`.

---

### Phase AI-3 — Image description

**Code:**

- Internal fetch of time-limited photo URL from photo-service (service key)  
- Vision call (`gpt-4o-mini` or similar) with safety prompt  
- Add `image_description` to schema and weave into `delivery_instructions`  

**Done when:** Reference photo produces a short appearance line in instructions (staging smoke with real photo).

---

### Phase AI-4 — Persist and surface

**Code:**

- Store `image_description`, `location_description` on order intent (`POST` payload / Postgres)  
- Web donor/coordinator detail panel shows fields  

**Done when:** Dashboard detail matches what the donor saw in generated instructions.

---

### Phase AI-5 — Soft seeker hints

**Code:**

- `seeker_handover_hints` string from compose step (notes + image + location descriptions)  
- Privacy review sign-off on prompt template  

**Done when:** Courier text has a single “Handover identification” block without biometric claims.

---

### Phase AI-6 — Hard match (later)

See [SharingBridge_Technical_Architecture.md](../design/SharingBridge_Technical_Architecture.md) §3.3 and photo-service roadmap. **Not** part of first LLM launch.

---

## Environment checklist

### ai-orchestration

| Variable | Purpose |
|----------|---------|
| `AI_LLM_MODE` | `deterministic` (CI/default) or `openai` |
| `OPENAI_API_KEY` | Provider key (Render secret) |
| `AI_LLM_MODEL` | e.g. `gpt-4o-mini`; vision step may use `gpt-4o` |
| `AI_ORCHESTRATION_INTERNAL_API_KEY` | Service-to-service auth |
| `PHOTO_SERVICE_BASE_URL` | Phase AI-3+ |
| `GEOCODING_*` | Phase AI-2 (provider-specific) |
| `SHARINGBRIDGE_WEBSITE_URL` | Instruction-pack intro line |

### integration-service

| Variable | Purpose |
|----------|---------|
| `AI_ORCHESTRATION_BASE_URL` | e.g. `https://sharingbridge-ai-orchestration.onrender.com` |
| `AI_SUGGEST_VENDORS_ENABLED` | `true` after AI-1 |
| `AI_INSTRUCTION_PACK_ENABLED` | `true` after AI-2+ |

---

## Testing strategy

| Layer | Approach |
|-------|----------|
| Unit | Mock LLM client; deterministic mode default |
| Integration | integration-service → mock orchestration HTTP (existing pattern) |
| Staging smoke | `AI_LLM_SMOKE_ENABLED=1` nightly optional; never in PR CI |
| Manual | [MANUAL_TESTING_GUIDE.md](../testing/MANUAL_TESTING_GUIDE.md) — extend after AI-1 |

---

## Decision log

| Date | Decision |
|------|----------|
| 2026-06 | **Direct OpenAI SDK pipelines** for MVP live LLM; LangChain deferred until RAG/agents needed |
| 2026-06 | GPS at **instruction generation** on mobile (committed `sharingbridge-mobile-app` `1f7f646`) |
| 2026-06 | Face match remains **photo-service** CV, not LLM |

---

## Document map

| Document | Role |
|----------|------|
| **This file** | Full AI phases, schemas, LangChain decision |
| [AI_PLATFORM_INTEGRATION.md](./AI_PLATFORM_INTEGRATION.md) | Service topology, sequences, env hosting |
| [ai-orchestration-local.md](../configuration/ai-orchestration-local.md) | Local three-service stack |
| [AGENT_HANDOFF.md](./AGENT_HANDOFF.md) | Shipped vs next tasks |
