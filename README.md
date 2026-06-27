# SharingBridge — Community meal coordination platform

> Affordable meals with dignity—for anyone who needs food, and for the people who arrange or pay for it

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Overview

SharingBridge is a mobile/web application that helps people **arrange and pay for meals**—for themselves, family, seniors, neighbours, or anyone they meet who needs food—through standard menus and third-party delivery or local vendors. The platform coordinates intent and handover; **payments stay with vendors** (facilitator, not merchant of record).

## Contributor notes (read this first)

Product-level assumptions: [SharingBridge_Business_Requirement.md](requirements/SharingBridge_Business_Requirement.md) § Operating Constraints. **Inclusive language** (initiator, payer, beneficiary, meal arrangement — not alms/donation framing): [PRODUCT_MODEL.md](development/PRODUCT_MODEL.md) § Documentation verbiage.

**AI-assisted development:** Code and docs are produced in AI-assisted sessions. **Progress vs plan:** [STATUS.md](development/STATUS.md). **How to run:** [configuration/README.md](configuration/README.md).

## Documentation guide

New here or unsure which file to open? Use this section. It defines **reading order**, **authority** (which doc wins when they disagree), and pointers — not duplicate content.

### Quick paths by goal

| I want to… | Read in order |
|------------|----------------|
| **Run the stack from scratch** | [configuration/README.md](configuration/README.md) → [e2e-deployment-sequence.md](configuration/e2e-deployment-sequence.md) → [database-setup-sequence.md](configuration/database-setup-sequence.md) |
| **Understand what is shipped vs plan** | [development/STATUS.md](development/STATUS.md) |
| **Engineering plan (long-term)** | [development/ENGINEERING_PLAN.md](development/ENGINEERING_PLAN.md) |
| **Agent session (next tasks)** | [development/AGENT_SESSION.md](development/AGENT_SESSION.md) |
| **Product vocabulary, verbiage & marketplace** | [development/PRODUCT_MODEL.md](development/PRODUCT_MODEL.md) § Documentation verbiage |
| **Configurator, unified initiation, payer** | [design/Configurator_Role_and_Unified_Initiation.md](design/Configurator_Role_and_Unified_Initiation.md) |
| **Eco kitchens — three routes, connection, payment boundaries** | [design/Eco_Kitchen_Initiation_Flow.md](design/Eco_Kitchen_Initiation_Flow.md) |
| **Handover location & map vendors (one vendor, thin adapters)** | [design/Location_Services_Vendor_Abstraction.md](design/Location_Services_Vendor_Abstraction.md) · [design/Handover_Location_Map_Picker.md](design/Handover_Location_Map_Picker.md) |
| **How we build (phases, repos, AI)** | [development/ENGINEERING_PLAN.md](development/ENGINEERING_PLAN.md) |
| **BRD steps 1–12 with diagrams** | [design/SharingBridge_End_to_End_Workflow.md](design/SharingBridge_End_to_End_Workflow.md) |
| **Order payment / delivery proof** | [design/Future_Extensions.md](design/Future_Extensions.md) § Phase A–B only |
| **Manual test on device** | [testing/MANUAL_TESTING_GUIDE.md](testing/MANUAL_TESTING_GUIDE.md) |

### Document hierarchy (authority)

When two docs conflict, **higher row wins** for that topic.

| Layer | Document | Owns |
|-------|----------|------|
| **1 — Requirements** | [requirements/SharingBridge_Business_Requirement.md](requirements/SharingBridge_Business_Requirement.md) | BRD, operating constraints |
| **2 — Product** | [development/PRODUCT_MODEL.md](development/PRODUCT_MODEL.md) | Glossary, **verbiage**, actors, initiation routes |
| **3 — Initiation flows** | [design/Eco_Kitchen_Initiation_Flow.md](design/Eco_Kitchen_Initiation_Flow.md) | Three routes, eco kitchens, connection + payment boundaries |
| **4 — Ops model** | [design/Configurator_Role_and_Unified_Initiation.md](design/Configurator_Role_and_Unified_Initiation.md) | Configurator vs runtime owners |
| **5 — Engineering** | [development/ENGINEERING_PLAN.md](development/ENGINEERING_PLAN.md) | Build phases, marketplace **E–I**, free-tier + scale tracks |
| **6 — Architecture** | [design/SharingBridge_Technical_Architecture.md](design/SharingBridge_Technical_Architecture.md) | Services, APIs, as-built MVP |
| **7 — Progress** | [development/STATUS.md](development/STATUS.md) | Shipped vs plan — **update when milestones land** |
| **8 — Agent sessions** | [development/AGENT_SESSION.md](development/AGENT_SESSION.md) | Next tasks, runbook, recent commits |
| **9 — Run & configure** | [configuration/](configuration/) | Deploy, env, auth, SQL sequence |
| **10 — Supplement** | [design/Future_Extensions.md](design/Future_Extensions.md) | Direct-order ops Phase A–B only |

Do not create parallel product-model files. Extend **PRODUCT_MODEL.md** (vocabulary), **Eco_Kitchen_Initiation_Flow.md** (initiation routes), or **ENGINEERING_PLAN.md** (engineering phases).

### Natural reading order (onboarding)

```text
1. requirements/SharingBridge_Business_Requirement.md     — business context
2. development/PRODUCT_MODEL.md                       — terms, actors, routes
3. design/Eco_Kitchen_Initiation_Flow.md                — three initiation routes (authoritative)
4. design/Configurator_Role_and_Unified_Initiation.md   — configurator, no daily ops desk
5. development/STATUS.md                              — shipped vs plan
6. development/AGENT_SESSION.md                         — agent sessions (optional)
7. design/SharingBridge_End_to_End_Workflow.md          — journey diagrams
8. configuration/e2e-deployment-sequence.md            — deploy
9. configuration/database-setup-sequence.md            — SQL order
10. Deep dives as needed (field-handoff, auth, testing)
```

### Roadmap docs — how they relate

```text
PRODUCT_MODEL.md              ← WHAT (vocabulary, initiation routes)
        ├── Eco_Kitchen_Initiation_Flow.md  ← three routes, connection, payment boundaries
        ├── Configurator_Role…  ← WHO owns ops vs config
        └── ENGINEERING_PLAN…     ← HOW / WHEN (phases E–I, repos)

Future_Extensions.md            ← Direct-order ops A–B supplement only
ENGINEERING_PLAN.md        ← Plan (phases, stack)
STATUS.md                       ← Shipped vs plan
AGENT_SESSION.md                  ← Agent next tasks
```

**Phase naming:** Future_Extensions **A–B** = order payment/delivery proof. ENGINEERING_PLAN **A–D** = AI/photo workstreams. ENGINEERING_PLAN **E–I** = marketplace engineering. (Future_Extensions Phase C is deprecated — use PRODUCT_MODEL § Marketplace.)

### Configuration folder

| Doc | Purpose |
|-----|---------|
| [configuration/README.md](configuration/README.md) | Deploy phases 0–5 |
| [database-setup-sequence.md](configuration/database-setup-sequence.md) | **SQL run order** |
| [database.md](configuration/database.md) | Supabase / local Postgres |
| [e2e-deployment-sequence.md](configuration/e2e-deployment-sequence.md) | OAuth → Render → verify |
| [environment-variables.md](configuration/environment-variables.md) | All env keys |
| [field-handoff.md](configuration/field-handoff.md) | Help a seeker / order intent |
| [design/Location_Services_Vendor_Abstraction.md](design/Location_Services_Vendor_Abstraction.md) | Map/geocode vendor strategy (one vendor per capability) |
| [design/Handover_Location_Map_Picker.md](design/Handover_Location_Map_Picker.md) | Cab-style handover map picker (shipped) |

## Key Features

- 🤝 **Dignity-first** — Respectful process for initiators, payers, and people receiving meals
- 🔒 **Handover guidance** - Fixed in-app copy for consent and surroundings (BRD step 4); geo safety service deferred
- 📱 **Multi-Platform** - iOS, Android, and Web applications
- 🛡️ **Facilitator-only money** - Payments and authoritative financial records stay with vendors/providers; see BRD *Operating Constraints*
- 📸 **Photo Verification** - Transparent delivery confirmation
- 🌐 **Multi-Vendor Support** - Integration with Swiggy, Zomato, Uber Eats

## Repository Structure

This is the **master repository** for SharingBridge (GitHub: [`sharingbridge/sharingbridge`](https://github.com/sharingbridge/sharingbridge)), containing documentation and overall coordination.

### Child Repositories (Independent Development)

**Frontend:**
- `sharingbridge-mobile-app` - Mobile application (Flutter)
- `sharingbridge-web-app` - Web application (Vite + React; coordinator dashboard)

**Backend Services:**
- `sharingbridge-api-gateway` - API gateway and routing
- `sharingbridge-order-service` - Order management
- `sharingbridge-user-service` - User authentication and profiles
- `sharingbridge-integration-service` - Vendor integrations (Swiggy, Zomato)
- `sharingbridge-notification-service` - Notifications

**AI/ML:**
- `sharingbridge-location-safety` - **Archived / deferred** (MVP uses mobile guidance only)
- `sharingbridge-photo-service` - Face detection and verification

**Infrastructure:**
- `sharingbridge-infra` - Infrastructure as Code
- `sharingbridge-deployment` - CI/CD pipelines

Each repository evolves independently. Coordination happens here through GitHub Discussions and `development/AGENT_SESSION.md`.

**Note:** Documentation is maintained within each service repository rather than in a separate docs repo.

## Project Status

🚧 **Status:** MVP in active development (mobile, web, integration-service on Render)  
📅 **Product model:** Eco kitchens + three initiation routes — [Eco_Kitchen_Initiation_Flow.md](design/Eco_Kitchen_Initiation_Flow.md)

## Problem Statement

Cash is ambiguous; **meals are concrete**. SharingBridge helps initiators and payers turn “this person needs food” (or “my parent needs lunch”) into a **tracked meal arrangement**—standard items, vendor payment, optional neighbourhood coordination—without the platform holding money.

## Solution

A facilitator platform that:
1. Connects **initiators and payers** with **people who need meals** (beneficiaries)
2. Shows handover guidance so the supporter can judge consent and surroundings (mobile; no geo safety score in MVP)
3. Creates orders through established food delivery platforms (or future direct-vendor flows)
4. Redirects payment to vendor or licensed provider systems (SharingBridge does not own financial tracking responsibility)
5. Confirms delivery with photo verification

## Technology Stack

**As-built (Render MVP)** — full detail in [Technical Architecture § As-built](design/SharingBridge_Technical_Architecture.md#as-built-architecture-june-2026).

### Frontend
- **Mobile:** Flutter (`sharingbridge-mobile-app`)
- **Web:** Vite + React (`sharingbridge-web-app`)

### Backend (MVP)
- **Experience API:** Node.js 20 — `sharingbridge-integration-service` (shared BFF for mobile + web)
- **System API:** Node.js 20 — `sharingbridge-user-service` (JWT, vendor presets / `donor_presets` table)
- **Process APIs:** FastAPI — `sharingbridge-ai-orchestration`, `sharingbridge-photo-service`
- **Database:** PostgreSQL (Supabase)

### AI/ML (MVP)
- **LLM:** Groq (text) + Gemini (vision) via ai-orchestration; `deterministic` mode for CI/offline
- **Geo:** Nominatim reverse geocode on integration-service (`/v1/geocode/reverse`); Google Maps **tiles only** on mobile when configured — [Location_Services_Vendor_Abstraction.md](design/Location_Services_Vendor_Abstraction.md)
- **Location safety service:** deferred; handover guidance in-app

### Infrastructure (MVP)
- **Hosting:** Render.com (APIs + static web)
- **CI/CD:** GitHub Actions per repo

**Scale target** (not MVP deploy): NestJS, API gateway, Redis/SQS, EKS — see [ENGINEERING_PLAN.md](development/ENGINEERING_PLAN.md).

## Architecture Highlights

```
Flutter mobile ──┐
                 ├──► integration-service (Experience API / BFF)
Vite/React web ──┘           │
                               ├──► user-service → Postgres (presets, auth)
                               ├──► ai-orchestration → Groq / Gemini / Nominatim
                               ├──► Postgres (order intents, marketplace, device_tokens)
                               ├──► photo-service (reference photos)
                               └──► notification-service (FCM on kitchen commit)
                                         ↓
                              Vendor deep links (Swiggy, Zomato, …)
```

**Eco kitchen stack:** `sharingbridge-notification-service` (FCM) — [configuration/notification-service-local.md](configuration/notification-service-local.md) · progressive setup [database-setup-sequence.md](configuration/database-setup-sequence.md).

**Not on Render for MVP:** api-gateway, order-service, location-safety (archived).

## Security & Privacy

- 🔐 JWT-based authentication
- 🔒 End-to-end encryption for sensitive data
- 🗑️ Auto-deletion of photos after 30 days
- ✅ GDPR/DPDPA compliant
- 🚫 No platform-owned payment ledger; minimize stored payment-related data (see BRD *Operating Constraints*)

## Getting Started

1. Read [Documentation guide](#documentation-guide) above.
2. Follow [configuration/e2e-deployment-sequence.md](configuration/e2e-deployment-sequence.md) (Phases 0–5).
3. Run SQL in order: [configuration/database-setup-sequence.md](configuration/database-setup-sequence.md).
4. Verify: [testing/MANUAL_TESTING_GUIDE.md](testing/MANUAL_TESTING_GUIDE.md).

## Contributing

We welcome contributors from all backgrounds - technical and non-technical!

- **Technical Contributors:** Developers, DevOps, AI/ML engineers - see [CALL_FOR_CONTRIBUTORS.md](development/CALL_FOR_CONTRIBUTORS.md)
- **Non-Technical Contributors:** Humanitarian workers, legal advisors, community volunteers, government liaisons - your expertise is crucial! Join our GitHub Discussions.
- **AI-Assisted Development:** Code and docs are produced through AI-assisted sessions. Coordination: [AGENT_SESSION.md](development/AGENT_SESSION.md). Run/deploy setup: [configuration/](configuration/README.md).

See [CALL_FOR_CONTRIBUTORS.md](development/CALL_FOR_CONTRIBUTORS.md) for detailed guidance.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

All contributions will be licensed under the MIT License.

## Contact

For inquiries about the SharingBridge project, please contact the development team.

---

*Building technology that serves humanity with dignity and compassion.*
