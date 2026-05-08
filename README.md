# ShareBridge - Digital Alms Platform

> Transforming traditional alms-giving into a modern, accountable, and dignified process

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Overview

ShareBridge is a mobile/web application that enables donors to provide food and essential items to alms seekers through verified third-party delivery services, eliminating cash transactions while maintaining dignity and convenience for both parties.

## Contributor notes (read this first)

Product-level assumptions are maintained in one place: [ShareBridge_Business_Requirement.md](requirements/ShareBridge_Business_Requirement.md), section **“Operating Constraints & Assumptions.”** Refer to that section as the source of truth.

**🤖 AI-Assisted Development:** This project is being built primarily through AI-assisted coding sessions. Live coordination, decisions, and the next set of recommended tasks are tracked in [AGENT_HANDOFF.md](development/AGENT_HANDOFF.md). Conversations are not archived in the repo — durable knowledge lives in design/, requirements/, development/, and testing/ docs.

## Key Features

- 🤝 **Dignity-First Approach** - Respectful process for both donors and seekers
- 🔒 **Safety Verification** - AI-powered location safety assessment
- 📱 **Multi-Platform** - iOS, Android, and Web applications
- 🛡️ **Facilitator-only money** - Payments and authoritative financial records stay with vendors/providers; see BRD *Operating Constraints*
- 📸 **Photo Verification** - Transparent delivery confirmation
- 🌐 **Multi-Vendor Support** - Integration with Swiggy, Zomato, Uber Eats

## Documentation

- [Business Requirements](requirements/ShareBridge_Business_Requirement.md) - Complete business case and benefits
- [Technical Architecture](design/ShareBridge_Technical_Architecture.md) - Detailed technical design
- [API Contracts](design/contracts/donor_setup_suggest_vendors.openapi.yaml) - Shared request/response contracts and examples
- [Implementation Approach](development/IMPLEMENTATION_APPROACH.md) - Development strategy and free-tier options
- [MVP Bootstrap Issues](development/MVP_BOOTSTRAP_ISSUES.md) - Per-repo kickoff issue/checklist definitions
- [Agent Handoff](development/AGENT_HANDOFF.md) - Live coordination doc and next recommended tasks
- [Manual Testing Guide](testing/MANUAL_TESTING_GUIDE.md) - How to verify the modules shipped so far
- [Initial Requirements](requirements/ShareBridge_initial_requirement.txt) - Original concept
- [Call for Contributors](development/CALL_FOR_CONTRIBUTORS.md) - How to get involved (technical & non-technical)

## Repository Structure

This is the **master repository** for ShareBridge, containing documentation and overall coordination.

### Child Repositories (Independent Development)

**Frontend:**
- `sharebridge-mobile-app` - Mobile application (Flutter)
- `sharebridge-web-app` - Web application (React/Next.js)

**Backend Services:**
- `sharebridge-api-gateway` - API gateway and routing
- `sharebridge-order-service` - Order management
- `sharebridge-user-service` - User authentication and profiles
- `sharebridge-integration-service` - Vendor integrations (Swiggy, Zomato)
- `sharebridge-notification-service` - Notifications

**AI/ML:**
- `sharebridge-ai-safety` - Location safety assessment
- `sharebridge-photo-service` - Face detection and verification

**Infrastructure:**
- `sharebridge-infra` - Infrastructure as Code
- `sharebridge-deployment` - CI/CD pipelines

Each repository evolves independently. Coordination happens here through GitHub Discussions and `development/AGENT_HANDOFF.md`.

**Note:** Documentation is maintained within each service repository rather than in a separate docs repo.

## Project Status

🚧 **Status:** Design Phase  
📅 **Date:** December 25, 2025

## Problem Statement

When meeting people seeking alms, donors face a moral dilemma: offering cash may support unintended uses rather than basic needs. ShareBridge ensures charitable intent is fulfilled by providing food and essentials through verified delivery services.

## Solution

A facilitator platform that:
1. Connects donors with alms seekers
2. Validates delivery location safety using AI
3. Creates orders through established food delivery platforms (or future direct-vendor flows)
4. Redirects payment to vendor or licensed provider systems (ShareBridge does not own financial tracking responsibility)
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
                                    ├── AI Safety Service
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
- **AI-Assisted Development:** Most artifacts are generated through AI-assisted coding sessions. The live coordination doc is [AGENT_HANDOFF.md](development/AGENT_HANDOFF.md).

See [CALL_FOR_CONTRIBUTORS.md](development/CALL_FOR_CONTRIBUTORS.md) for detailed guidance.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

All contributions will be licensed under the MIT License.

## Contact

For inquiries about the ShareBridge project, please contact the development team.

---

*Building technology that serves humanity with dignity and compassion.*
