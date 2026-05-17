# SharingBridge configuration

Operational and deployment configuration by application area. Design specs remain in `design/` and `requirements/`; this folder is for **how to run and wire** the MVP.

| Document | Scope |
|----------|--------|
| [backend-render.md](./backend-render.md) | Host user-service, ai-orchestration, and integration-service on Render |
| [authentication.md](./authentication.md) | Donor JWT and internal service API key |
| [mobile-client.md](./mobile-client.md) | Flutter `dart-define` values and hosted vs local URLs |
| [web-client.md](./web-client.md) | Web dashboard (order initiation history) and CORS |
| [field-handoff.md](./field-handoff.md) | Offer food help flow, guidance (BRD step 4), what is not automated |

**Per-repo templates:** each service repository has `.env.example` and `render.yaml` (where applicable).

**Testing:** [MANUAL_TESTING_GUIDE.md](../testing/MANUAL_TESTING_GUIDE.md)
