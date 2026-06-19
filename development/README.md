# Development docs

**Start:** [README.md § Documentation guide](../README.md#documentation-guide)

## Two-doc model (no duplicate “where we are”)

| Document | Role | Update when |
|----------|------|-------------|
| **[IMPLEMENTATION_APPROACH.md](./IMPLEMENTATION_APPROACH.md)** | **Plan** — phases, free-tier stack, long-term scale | Strategy or phase definitions change |
| **[PROGRESS.md](./PROGRESS.md)** | **Progress** — shipped vs plan, repos, AI snapshot, SQL gaps | A milestone ships or env checklist changes |
| **[PRODUCT_ROADMAP.md](./PRODUCT_ROADMAP.md)** | **Product** — glossary, actors, routes (not progress) | Vocabulary or marketplace model changes |
| **[AGENT_HANDOFF.md](./AGENT_HANDOFF.md)** | **Agent sessions** — next tasks, runbook, recent commits | Each coding session |

## Other development docs

| Document | Role |
|----------|------|
| [AI_PLATFORM_INTEGRATION.md](./AI_PLATFORM_INTEGRATION.md) | AI **as-built** wiring (integration → orchestration → Groq/Gemini) |
| [AI_IMPLEMENTATION_PLAN.md](./AI_IMPLEMENTATION_PLAN.md) | AI **future** phases and provider split |
| [USER_SERVICE_PREFERENCES_MIGRATION.md](./USER_SERVICE_PREFERENCES_MIGRATION.md) | Preferences migration (**complete**) |
| [CALL_FOR_CONTRIBUTORS.md](./CALL_FOR_CONTRIBUTORS.md) | Contributing |

## Design (product + architecture)

| Document | Role |
|----------|------|
| [Eco_Kitchen_Initiation_Flow.md](../design/Eco_Kitchen_Initiation_Flow.md) | Three routes, connection, payment boundaries |
| [Configurator_Role_and_Unified_Initiation.md](../design/Configurator_Role_and_Unified_Initiation.md) | Configurator vs daily ops |
| [Future_Extensions.md](../design/Future_Extensions.md) | Direct-order ops supplement (A–B) |
| [SharingBridge_End_to_End_Workflow.md](../design/SharingBridge_End_to_End_Workflow.md) | BRD journey diagrams |

**Run and deploy** → [configuration/README.md](../configuration/README.md) · **SQL** → [database-setup-sequence.md](../configuration/database-setup-sequence.md)
