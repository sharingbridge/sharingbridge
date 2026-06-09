# Service startup — FastAPI (ai-orchestration) and Node (integration / user-service)

SharingBridge MVP backends use **FastAPI + Uvicorn** (Python) and **plain Node.js HTTP** servers — not NestJS in production today. NestJS is a scale target only ([AGENT_HANDOFF.md](../development/AGENT_HANDOFF.md)).

---

## FastAPI — `sharingbridge-ai-orchestration`

### Boot sequence

1. **Process start** — Render runs the Docker image `CMD` (`start.sh` → `uvicorn app.main:app`).
2. **Import time** — `app/main.py` loads settings (`app/config.py`), configures logging (`service_log.configure_logging`), registers routes on the `FastAPI()` instance.
3. **Startup event** — `@app.on_event("startup")` runs `log_startup_config()`:
   - Builds a **non-secret** config snapshot (`llm_mode`, keys *configured* yes/no, models).
   - Calls `log_startup_from_issues()` — at `LOG_LEVEL=warn` (default) only **misconfiguration warnings** print; at `info`, full `[startup] config {…}` JSON.
4. **Ready** — Uvicorn listens on `PORT`; `/health` returns `ok` + config (no API keys).

### What does *not* run at startup

- No DB migrations, no background workers, no model warm-up.
- LLM clients are created **per request** inside `instruction_pack_live` / `suggest_vendors_live`.

### Operator checks after deploy

```powershell
curl https://<ai-host>.onrender.com/health
```

Expect `llm_mode: live`, `gemini_vision_model: gemini-2.5-flash`, `groq_configured: true`, `gemini_configured: true`.

---

## Node — `sharingbridge-integration-service` and `sharingbridge-user-service`

### Boot sequence

1. **`npm start`** → `node src/server.js` with `import "dotenv/config"` (local `.env` only).
2. **Module load** — imports routes, stores, auth; constructs `AiOrchestrationClient`, `OrderIntentStore` / Postgres pool, `PostgresSeekerDemandStore` (when `DATABASE_URL` set), `UserServicePreferencesRepository`.
3. **Postgres guard** (integration) — `assertOrderIntentGeoSchema()` may fail fast if geo columns missing; `seeker_demands` is optional at boot — store sets `enabled: false` until [schema-seeker-demands-migration.sql](./schema-seeker-demands-migration.sql) is applied.
4. **HTTP listen** — `createServer` callback handles routes; on listen:
   - `logListenMessage()` — port + service name.
   - `logStartupDiagnostics(buildStartupConfig())` — AI bridge flags, timeouts, DB URL set, CORS set; warnings only at `LOG_LEVEL=warn`.

### What does *not* run at startup

- No Nest modules, no dependency-injection container.
- AI orchestration is **not** called at boot — only on `POST /v1/donor-setup/suggest-vendors` and `POST /v1/donor-seeker/instruction-pack`.
- Seeker demand routes (`POST/GET /v1/seeker-demands`, `GET /v1/demand/board`) read/write Postgres only when `seeker_demands` exists — see [field-handoff.md](./field-handoff.md) § Seeker demand.

### Operator checks after deploy

```powershell
curl https://<integration-host>.onrender.com/health
```

Expect `ai.orchestration_base_url_set: true`, `instruction_pack_timeout_ms: 60000`, `internal_api_key_set: true`.

---

## NestJS (future)

If services migrate to NestJS, startup would move to `main.ts` → `NestFactory.create(AppModule)` → `app.listen(PORT)` with `onModuleInit` hooks for config validation. Today’s behaviour maps to:

| Current (Node/FastAPI) | Nest equivalent |
|------------------------|-----------------|
| `dotenv/config` | `ConfigModule.forRoot()` |
| `logStartupDiagnostics` | `OnModuleInit` + custom `Logger` |
| Route `if` chain in `server.js` | `@Controller` + `@Get` / `@Post` |
| FastAPI `@app.on_event("startup")` | `onModuleInit` or `OnApplicationBootstrap` |

---

## Logging default

Set **`LOG_LEVEL=warn`** on all four backend APIs in Render (you did this). Use `info` temporarily when debugging instruction-pack latency — see [ai-setup-handhold.md](./ai-setup-handhold.md) §6e.
