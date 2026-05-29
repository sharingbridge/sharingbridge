# SharingBridge - Digital Alms Platform

> Transforming traditional alms-giving into a modern, accountable, and dignified process

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Overview

SharingBridge is a mobile/web application that enables donors to provide food and essential items to alms seekers through verified third-party delivery services, eliminating cash transactions while maintaining dignity and convenience for both parties.

## Contributor notes (read this first)

Product-level assumptions are maintained in one place: [SharingBridge_Business_Requirement.md](requirements/SharingBridge_Business_Requirement.md), section **“Operating Constraints & Assumptions.”** Refer to that section as the source of truth.

**🤖 AI-Assisted Development:** This project is being built primarily through AI-assisted coding sessions. Live coordination, decisions, doc map, and next tasks: [AGENT_HANDOFF.md](development/AGENT_HANDOFF.md). Conversations are not archived in the repo — durable knowledge lives in design/, requirements/, development/, and testing/ docs.

## Key Features

- 🤝 **Dignity-First Approach** - Respectful process for both donors and seekers
- 🔒 **Handover guidance** - Fixed in-app copy for consent and surroundings (BRD step 4); geo safety service deferred
- 📱 **Multi-Platform** - iOS, Android, and Web applications
- 🛡️ **Facilitator-only money** - Payments and authoritative financial records stay with vendors/providers; see BRD *Operating Constraints*
- 📸 **Photo Verification** - Transparent delivery confirmation
- 🌐 **Multi-Vendor Support** - Integration with Swiggy, Zomato, Uber Eats

## Documentation

- [Business Requirements](requirements/SharingBridge_Business_Requirement.md) - Complete business case and benefits
- [End-to-End Workflow (diagrams)](design/SharingBridge_End_to_End_Workflow.md) - Full journey steps 1–12 with Mermaid flows; shipped vs planned
- [Future Extensions](design/Future_Extensions.md) - Order payment/delivery tracking, delivery proof, locality demand & vendor bidding (roadmap)
- [Technical Architecture](design/SharingBridge_Technical_Architecture.md) - Detailed technical design
- [API Contracts](design/contracts/donor_setup_suggest_vendors.openapi.yaml) - Shared request/response contracts and examples
- [Implementation Approach](development/IMPLEMENTATION_APPROACH.md) - Development strategy and free-tier options
- [Configuration](./configuration/README.md) - Render deploy, auth, mobile client, field handoff
- [AI Platform Integration](development/AI_PLATFORM_INTEGRATION.md) - LangChain/orchestration hosting, model APIs, and bridges from mobile/backend to AI modules (planned)
- [MVP Bootstrap Issues](development/MVP_BOOTSTRAP_ISSUES.md) - Per-repo kickoff issue/checklist definitions
- [Agent Handoff](development/AGENT_HANDOFF.md) - Live coordination doc and next recommended tasks
- [Manual Testing Guide](testing/MANUAL_TESTING_GUIDE.md) - How to verify the modules shipped so far
- [Initial Requirements](requirements/SharingBridge_initial_requirement.txt) - Original concept
- [Call for Contributors](development/CALL_FOR_CONTRIBUTORS.md) - How to get involved (technical & non-technical)

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

Each repository evolves independently. Coordination happens here through GitHub Discussions and `development/AGENT_HANDOFF.md`.

**Note:** Documentation is maintained within each service repository rather than in a separate docs repo.

## Project Status

🚧 **Status:** Design Phase  
📅 **Date:** December 25, 2025

## Problem Statement

When meeting people seeking alms, donors face a moral dilemma: offering cash may support unintended uses rather than basic needs. SharingBridge ensures charitable intent is fulfilled by providing food and essentials through verified delivery services.

## Solution

A facilitator platform that:
1. Connects donors with alms seekers
2. Shows handover guidance so the donor can judge consent and surroundings (mobile; no geo safety score in MVP)
3. Creates orders through established food delivery platforms (or future direct-vendor flows)
4. Redirects payment to vendor or licensed provider systems (SharingBridge does not own financial tracking responsibility)
5. Confirms delivery with photo verification

## Technology Stack

### Frontend
- **Mobile:** React Native / Flutter
- **Web:** React / Next.js

### Backend
- **Framework:** Node.js (NestJS) / Python (FastAPI)
- **Database:** PostgreSQL with PostGIS
- **Cache:** Redis
- **Message Queue:** Redis Streams/PubSub (MVP), AWS SQS/SNS (scale)

### AI/ML
- **Framework:** TensorFlow / PyTorch (for face recognition only)
- **Location Safety:** API-based rule system (Google Maps, Places, OpenWeather); Custom ML optional at scale
- **Face Recognition:** Pre-trained models (FaceNet/DeepFace)

### Infrastructure
- **Cloud:** AWS / Azure / GCP
- **Container Orchestration:** Kubernetes (EKS)
- **CI/CD:** GitHub Actions

## Architecture Highlights

```
Mobile/Web App → API Gateway → Microservices
                                    ├── User Service
                                    ├── Order Service
                                    ├── Location Safety Service
                                    ├── Photo Service
                                    ├── Integration Service
                                    └── Notification Service
                                           ↓
                              External Vendor APIs
                              (Swiggy, Zomato, Uber Eats)
```

## Security & Privacy

- 🔐 JWT-based authentication
- 🔒 End-to-end encryption for sensitive data
- 🗑️ Auto-deletion of photos after 30 days
- ✅ GDPR/DPDPA compliant
- 🚫 No platform-owned payment ledger; minimize stored payment-related data (see BRD *Operating Constraints*)

## Getting Started

> Coming soon - Development setup instructions

## Contributing

We welcome contributors from all backgrounds - technical and non-technical!

- **Technical Contributors:** Developers, DevOps, AI/ML engineers - see [CALL_FOR_CONTRIBUTORS.md](development/CALL_FOR_CONTRIBUTORS.md)
- **Non-Technical Contributors:** Humanitarian workers, legal advisors, community volunteers, government liaisons - your expertise is crucial! Join our GitHub Discussions.
- **AI-Assisted Development:** Code and docs are produced through AI-assisted sessions. Coordination: [AGENT_HANDOFF.md](development/AGENT_HANDOFF.md). Run/deploy setup: [configuration/](configuration/README.md).

See [CALL_FOR_CONTRIBUTORS.md](development/CALL_FOR_CONTRIBUTORS.md) for detailed guidance.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

All contributions will be licensed under the MIT License.

## Contact

For inquiries about the SharingBridge project, please contact the development team.

---

*Building technology that serves humanity with dignity and compassion.*
