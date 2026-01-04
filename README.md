# Ketpaar (கேட்பார்) - Digital Alms Platform

> Transforming traditional alms-giving into a modern, accountable, and dignified process

## Overview

Ketpaar is a mobile/web application that enables donors to provide food and essential items to alms seekers through verified third-party delivery services, eliminating cash transactions while maintaining dignity and convenience for both parties.

## Key Features

- 🤝 **Dignity-First Approach** - Respectful process for both donors and seekers
- 🔒 **Safety Verification** - AI-powered location safety assessment
- 📱 **Multi-Platform** - iOS, Android, and Web applications
- 🛡️ **Zero Payment Liability** - Direct vendor payment integration (no payment handling)
- 📸 **Photo Verification** - Transparent delivery confirmation
- 🌐 **Multi-Vendor Support** - Integration with Swiggy, Zomato, Uber Eats

## Documentation

- [Business Requirements](Ketpaar_Business_Requirement.md) - Complete business case and benefits
- [Technical Architecture](Ketpaar_Technical_Architecture.md) - Detailed technical design
- [Initial Requirements](Ketpaar_initial_requirement.txt) - Original concept
- [Call for Contributors](CALL_FOR_CONTRIBUTORS.md) - How to get involved

## Repository Structure

This is the **master repository** for Ketpaar, containing documentation and overall coordination.

### Child Repositories (Independent Development)

**Frontend:**
- `ketpaar-mobile-app` - Mobile application (React Native/Flutter)
- `ketpaar-web-app` - Web application (React/Next.js)

**Backend Services:**
- `ketpaar-api-gateway` - API gateway and routing
- `ketpaar-order-service` - Order management
- `ketpaar-user-service` - User authentication and profiles
- `ketpaar-integration-service` - Vendor integrations (Swiggy, Zomato)
- `ketpaar-notification-service` - Notifications

**AI/ML:**
- `ketpaar-ai-safety` - Location safety assessment
- `ketpaar-photo-service` - Face detection and verification

**Infrastructure:**
- `ketpaar-infra` - Infrastructure as Code
- `ketpaar-deployment` - CI/CD pipelines

**Documentation:**
- `ketpaar-docs` - User guides and API docs

Each repository evolves independently. Coordination happens here.

## Project Status

🚧 **Status:** Design Phase  
📅 **Date:** December 25, 2025

## Problem Statement

When encountering people seeking alms, donors face a moral dilemma: offering cash may support unintended uses rather than basic needs. Ketpaar ensures charitable intent is fulfilled by providing food and essentials through verified delivery services.

## Solution

A facilitator platform that:
1. Connects donors with alms seekers
2. Validates delivery location safety using AI
3. Creates orders through established food delivery platforms
4. Redirects payment to vendor systems (no payment handling)
5. Confirms delivery with photo verification

## Technology Stack

### Frontend
- **Mobile:** React Native / Flutter
- **Web:** React / Next.js

### Backend
- **Framework:** Node.js (NestJS) / Python (FastAPI)
- **Database:** PostgreSQL with PostGIS
- **Cache:** Redis
- **Message Queue:** RabbitMQ / AWS SQS

### AI/ML
- **Framework:** TensorFlow / PyTorch
- **Location Safety:** Custom ML model for safety scoring

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
- 🚫 Zero payment data handling

## Getting Started

> Coming soon - Development setup instructions

## Contributing

> Coming soon - Contribution guidelines

## License

> TBD

## Contact

For inquiries about the Ketpaar project, please contact the development team.

---

**கேட்பார்** - "Those who ask" in Tamil

*Building technology that serves humanity with dignity and compassion.*
