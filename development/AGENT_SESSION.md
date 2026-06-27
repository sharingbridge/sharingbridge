# SharingBridge — agent session

> **AI session doc.** Update **Next tasks** and **Recently shipped** when work lands. **Do not** duplicate progress tables here — use [STATUS.md](./STATUS.md).

## Goal

MVP **initiator vendor presets → Help a seeker / eco kitchen initiation → vendor redirect → delivery confirmation**, plus **eco kitchen** routes (Actions, Connection, FCM). Legacy code paths still use `donor_*` module names. **`sharingbridge-integration-service`** is the Experience API (BFF). SharingBridge is never the system of record for money.

## Locked approach

- Payments: provider/vendor-hosted only; no platform ledger.
- Mobile: Flutter; MVP backends: Node 20 HTTP (not NestJS in production).
- Preferences: user-service Postgres authority; client cache non-authoritative.
- Labels: Experience API = integration-service; Process = ai-orchestration, photo-service, notification-service; System = user-service + Postgres.

Full progress vs plan: **[STATUS.md](./STATUS.md)**.

---

## Documentation map

| If you need… | Read |
|--------------|------|
| **Progress vs plan (update this when shipping)** | [STATUS.md](./STATUS.md) |
| **Engineering plan (long-term)** | [ENGINEERING_PLAN.md](./ENGINEERING_PLAN.md) |
| **Product vocabulary** | [PRODUCT_MODEL.md](./PRODUCT_MODEL.md) |
| **Run / deploy order** | [configuration/e2e-deployment-sequence.md](../configuration/e2e-deployment-sequence.md) |
| **SQL order** | [configuration/database-setup-sequence.md](../configuration/database-setup-sequence.md) |
| **Manual tests** | [testing/MANUAL_TESTING_GUIDE.md](../testing/MANUAL_TESTING_GUIDE.md) |
| **Eco kitchen flows** | [design/Eco_Kitchen_Initiation_Flow.md](../design/Eco_Kitchen_Initiation_Flow.md) |
| **Handover location (steps 10–13)** | [README.md § Documentation guide](../README.md#documentation-guide) — field-handoff → vendor ADR → map picker → mobile-client |
| **AI as-built** | [AI_AS_BUILT.md](./AI_AS_BUILT.md) |
| **AI future phases** | [AI_PLAN.md](./AI_PLAN.md) |
| **Full doc index** | [README.md § Documentation guide](../README.md#documentation-guide) |

Prefer `configuration/*` and `MANUAL_TESTING_GUIDE.md` over per-repo READMEs for runbooks.

---

## Quick runbook

```text
integration-service   npm test && npm start     → :8080
user-service          npm test && npm start     → :8081
ai-orchestration      pytest -q && uvicorn…     → :8091
photo-service         (venv) pytest && uvicorn  → :8092
notification-service  npm test && npm start     → :8093
web-app               npm test && npm run dev    → :5173
mobile                flutter test && flutter run (see mobile-client.md)
```

Google sign-in and emulator URLs: [configuration/mobile-client.md](../configuration/mobile-client.md). Dev JWT: `node scripts/mint-dev-jwt.mjs demo-user initiator` in user-service.

---

## GitHub org (`sharingbridge`)

| Role | Slug |
|------|------|
| Coordination / docs | `sharingbridge` |
| Core APIs | `sharingbridge-user-service`, `sharingbridge-integration-service` |
| Clients | `sharingbridge-mobile-app`, `sharingbridge-web-app` |
| Process services | `sharingbridge-ai-orchestration`, `sharingbridge-photo-service`, `sharingbridge-notification-service` |
| Not MVP | `sharingbridge-api-gateway`, `sharingbridge-order-service`, `sharingbridge-location-safety` (archived) |

---

## Next recommended tasks

1. **Transactional email** — Resend/SendGrid in notification-service.
2. **Order ops + delivery proof** — [Future_Extensions.md](../design/Future_Extensions.md) Phase B.
3. **Marketplace F** — beneficiary profile (see [ENGINEERING_PLAN.md](./ENGINEERING_PLAN.md) § F).
4. **Mobile Connection UI** — in-app order-code lookup.

After shipping, update [STATUS.md](./STATUS.md) workstream table.

---

## Post-ship checklist

1. CI green on `main` for every repo you changed.
2. Short smoke from [MANUAL_TESTING_GUIDE.md](../testing/MANUAL_TESTING_GUIDE.md).
3. Update [STATUS.md](./STATUS.md) if a workstream status changed.
4. Add a line under **Recently shipped** below.

---

## Recently shipped (newest last)

- `feat` (web): **Updates** banner — connection-ready rows on sign-in/Refresh; Open Connection → Actions.
- `docs`: Progressive SQL setup; notification deploy path; manual guide §4d-b.
- `feat`: Eco kitchen phases 1–6; Connection API; FCM webhook; mobile **Eco kitchen · I pay**.
- `feat`: Marketplace M1–M4 in code; Actions tab; seeker demands; kitchen commit.
- `feat`: AI orchestration wired (deterministic + `AI_LLM_MODE=live` Groq/Gemini).
- `feat`: Postgres-only persistence; user-service preferences authority.
- `feat`: Google Sign-In; coordinator dashboard; Initiations / Actions / Map.

Older history: git log on `sharingbridge` and service repos.
