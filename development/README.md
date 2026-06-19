# Development docs

**Start:** [README.md § Documentation guide](../README.md#documentation-guide)

## Naming (what each file means)

| File | Means | Not |
|------|--------|-----|
| [ENGINEERING_PLAN.md](./ENGINEERING_PLAN.md) | Long-term **build strategy** — phases, stack, scale path | Current sprint status |
| [STATUS.md](./STATUS.md) | **Shipped vs plan** — update when milestones land | Product vocabulary |
| [PRODUCT_MODEL.md](./PRODUCT_MODEL.md) | **Domain model** — actors, terms, initiation routes, marketplace concepts | Timeline or deploy steps |
| [AGENT_SESSION.md](./AGENT_SESSION.md) | **Coding session** notes — next tasks, runbook | Full API reference |
| [AI_AS_BUILT.md](./AI_AS_BUILT.md) | How AI is **wired today** | Future AI phases |
| [AI_PLAN.md](./AI_PLAN.md) | AI **future** phases (delivery match, etc.) | Env setup (see `configuration/ai-setup-handhold.md`) |

**Why not “roadmap”?** In this repo, *roadmap* sounded like a schedule. **PRODUCT_MODEL** is vocabulary and actors; **ENGINEERING_PLAN** is how we build; **STATUS** is where we are.

**Former names (June 2026 rename):** `PRODUCT_ROADMAP` → `PRODUCT_MODEL`, `IMPLEMENTATION_APPROACH` → `ENGINEERING_PLAN`, `PROGRESS` → `STATUS`, `AGENT_HANDOFF` → `AGENT_SESSION`, `AI_PLATFORM_INTEGRATION` → `AI_AS_BUILT`, `AI_IMPLEMENTATION_PLAN` → `AI_PLAN`. Removed `USER_SERVICE_PREFERENCES_MIGRATION.md` (complete — see [authentication.md](../configuration/authentication.md) § Preferences).

## Read order

1. [PRODUCT_MODEL.md](./PRODUCT_MODEL.md) — terms and actors  
2. [STATUS.md](./STATUS.md) — what is shipped  
3. [ENGINEERING_PLAN.md](./ENGINEERING_PLAN.md) — planned phases (when planning ahead)  
4. [AGENT_SESSION.md](./AGENT_SESSION.md) — if you are continuing an AI coding session  

## Design (product + architecture)

| Document | Role |
|----------|------|
| [Eco_Kitchen_Initiation_Flow.md](../design/Eco_Kitchen_Initiation_Flow.md) | Three routes, connection, payment boundaries |
| [Configurator_Role_and_Unified_Initiation.md](../design/Configurator_Role_and_Unified_Initiation.md) | Configurator vs daily ops |
| [Future_Extensions.md](../design/Future_Extensions.md) | Direct-order ops supplement (A–B) |
| [SharingBridge_End_to_End_Workflow.md](../design/SharingBridge_End_to_End_Workflow.md) | BRD journey diagrams |

**Run and deploy** → [configuration/README.md](../configuration/README.md) · **SQL** → [database-setup-sequence.md](../configuration/database-setup-sequence.md)
