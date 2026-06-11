# **SharingBridge - Community meal coordination platform**

## **Problem Statement**
People often want to help with **food**—for someone they meet, a parent, a senior neighbour, or themselves—but **cash is ambiguous** and **meal logistics are fragmented** (which vendor, what to order, how to pay, how to confirm handover). There is no lightweight way to turn “they need a meal” into a **standard item, vendor payment, and tracked handover** without the platform holding money.

## **Solution**
SharingBridge is a mobile/web application that helps **payees and demand initiators** arrange meals for **beneficiaries** through standard menus and third-party delivery or local vendors—maintaining dignity and convenience. **The platform acts as a facilitator only; all payments are processed directly through the vendor's payment system.**

### **Core Workflow:**
1. **Vendor preset setup (before field use)** — Signed-in user saves preferred vendors and menu deep links via an AI-assisted flow (fixed prompt + structured output).
2. **Real-world trigger** — Someone needs a meal (in person, remotely, or on behalf of family); the initiator or payee opens the app.
3. **Initial Conversation and Consent** - Payee confirms food help intent and gets consent to capture beneficiary details/photo for delivery identification.
4. **Quick Guidance (Early)** - During this initial interaction, the app shows short, fixed guidance on consent, handover conditions, and surroundings. The payee decides whether to continue; SharingBridge does not certify that a location is safe.
5. **Create Order Intent** - Payee captures beneficiary context and chooses a prepared order option.
6. **Generate Delivery Instruction Pack** - App uses AI to create clean, non-offensive delivery instructions from payee input (for example: visible appearance cues, current geolocation, order summary, and secure photo reference). Payee can copy-paste this text into the delivery app instruction field.
7. **Store Photo + Instruction Securely** - App stores the beneficiary photo and generated instruction text in a secure external repository and includes only the required reference/link in delivery instructions.
8. **Place Order** - Order is created through external food delivery platforms (or through the direct-vendor flow once that flow is fully implemented).
9. **Pay Externally** - Payee completes payment in vendor or licensed provider systems.
10. **Deliver and Verify** - Delivery personnel identify the beneficiary and complete handover; delivery photo/evidence is captured.
11. **Confirm to Payee** - Payee receives completion status and verification details.
12. **View History** - Payees/admins can see nearby and past order outcomes.

## **Operating Constraints & Assumptions**

This section defines product constraints for volunteer-led, agile delivery.

- **Intent to help with food, light process:** Development is expected to be **iterative** (short cycles, progressive refinement). Edge cases—especially **privacy** and **unhappy paths**—are specified and hardened **over time**, not all upfront.
- **Beneficiaries:** Beneficiaries are **not registered users** and do not log in.
- **Facilitation, not finance:** SharingBridge is a **facilitator**. The platform **does not own financial tracking responsibility**—no authoritative **ledger of record**, settlement, or institutional money-handling role. **Payments and balances live with vendors and licensed payment providers.** The product may store **non-authoritative** data needed for coordination and UX (for example order state, external vendor order references), only as narrowly as implementation requires, and with retention rules to be tightened as privacy work proceeds.
- **Pledges and community pools:** Pledges describe **voluntary intent** from willing participants, **not legally binding commitments** and not a regulated pooled account unless a future scope explicitly says otherwise (with professional advice). **Orchestration**—who gets notified when, how intent becomes a fulfilled order, expiry, partial fulfillment, cancellation—**is not fully specified yet** and will be designed as those features mature.
- **Direct vendor flow:** Optional flow; implementation details are still being finalized. Same money principle applies: **no platform-owned financial responsibility.**

## **Key Benefits**

**For payees and initiators:**
- Turns intent to help with food into a concrete meal arrangement (standard items where configured)
- Provides delivery confirmation with photo proof
- Secure payment through trusted vendor platforms (Zomato, Swiggy, etc.)
- Peace of mind about proper fund utilization
- No platform-owned payment credentials or settlement ledgers; only non-authoritative coordination data as needed (see *Operating Constraints*)
- Flexible funding options: direct pay, pledge, or crowdfund
- Community impact visibility

**For People who need meals:**
- Guaranteed food/essential items instead of uncertain cash
- Maintains dignity through respectful process
- Reduced uncertainty through direct order visibility and confirmation
- Multiple fulfillment options (delivery, vendor pickup, community support)
- Faster access through pledge pools

**For Vendors:**
- Social recognition and community visibility
- CSR (Corporate Social Responsibility) credits
- Direct community engagement without app development costs
- Better planning through vendor capacity slots and scheduled preparation

**For Society:**
- Reduces misuse of meal-support funds
- Promotes safe, transparent giving
- Leverages existing delivery infrastructure
- Creates community solidarity through crowdfunding
- Empowers small businesses to participate in social good

## **Technical Design**

### **Architecture Components:**

**1. Mobile/Web Application (Frontend)**
- Cross-platform (iOS, Android, Web)
- Camera integration for photo capture
- Real-time order tracking interface

**2. Backend Services**
- RESTful API for order management
- User authentication & authorization
- Order history and transaction logs

**3. Field handover guidance (mobile — BRD step 4)**
- **Fixed in-app guidance** in plain language (consent, surroundings, visibility, photo policy, payee judgment)
- **Not** a backend safety score or pass/fail gate for MVP
- Optional future: post-delivery feedback for ops analytics only (non-certifying); see coordination docs

**3b. Photo & Verification Module** (`sharingbridge-photo-service`)
- Encrypted photo storage (reference at payee interaction; delivery acknowledgement)
- Face embeddings and computer-vision pipelines (not LLM):
  - **Assistance history review** (informational, non-blocking): compare photo + location to recent help within configurable time/proximity; inform payee only — never block the meal arrangement
  - **Payee ↔ delivery photo match** at handover verification
- Optional privacy controls (e.g. blur) where supported

**4. Integration Layer**
- External food delivery API connectors (Swiggy, Zomato, Uber Eats)
- OAuth/Deep linking for vendor payment redirect
- Webhook listeners for order status updates
- AI-generated delivery instruction text builder (copy-paste ready for vendor apps)
- Photo storage (cloud-based)
  - Push notification service (default)
  - In-app notification service (default)
  - Email notification service (default)
  - (Optional/Future) SMS notification service

**5. Data Management**
- Location coordinates storage
- Photo storage with privacy compliance
- Generated delivery instruction text with content safety controls (no offensive, illegal, or sensitive wording)
- Non-authoritative order and status records (coordination—not a financial ledger of record)
- Safety metrics and analytics
- Voluntary pledge intent and allocation signals (orchestration TBD; not a binding or regulated ledger unless separately scoped)
- Vendor registry and ratings
- Crowdfunding campaign coordination (contributor visibility and thresholds; settlement via providers/vendors)

### **Key Technical Features:**
- **Handover guidance** — fixed copy in the mobile field flow (BRD step 4); no geo safety score in MVP
- **Multi-vendor integration** for wider coverage
- **Photo verification** at both ends (order & delivery)
- **Real-time notifications** for order status (push, in-app, email by default; SMS optional/future)
- **Privacy-first design** (encrypted photo storage, limited retention)
- **Payment delegation** - Money movement and authoritative records live with vendors and licensed payment providers; SharingBridge does not own financial tracking responsibility (see *Operating Constraints*)
- **Webhook integration** for order tracking without payment handling

### **Technology Stack (Proposed):**
- **Mobile:** React Native / Flutter
- **Backend:** Node.js / Python (Django/FastAPI)
- **Field guidance:** `sharingbridge-mobile-app` — BRD step 4; `sharingbridge-location-safety` **deferred/archived** (see repo README)
- **Photo / face pipelines:** `sharingbridge-photo-service` — embeddings (e.g. FaceNet/DeepFace class models) for assistance-history hints and delivery match
- **LLM orchestration:** `sharingbridge-ai-orchestration` — instruction pack and donor-setup suggestions (see coordination `AI_PLATFORM_INTEGRATION.md`)
- **Database:** PostgreSQL with PostGIS for location data
- **Cloud:** AWS/Azure/GCP
- **APIs:** Food delivery platform APIs, Logistics partner APIs (Dunzo/Porter/Shadowfax)

## **Future Extensions**

#### **1. Pledge Pool System**
Payees can pledge money in advance for future seekers they have not met yet.
- **How it works:**
  - Payees pledge amount (₹100, ₹500, ₹1000, etc.) to a common pool
  - When any payee meets a seeker, they can use pledged funds instead of paying directly
  - Pledges can be earmarked (location-based, time-based, or general)
  - Real-time dashboard shows pledge utilization
- **Benefits:** Enables giving even when not physically present, creates community fund
- **Orchestration (TBD):** Matching pledges to live donor-seeker interactions, notifications to pledgors and other parties, expiry, cancellation, and visibility rules are to be designed as the feature set matures, without the platform taking on financial tracking responsibility.

#### **2. Direct Vendor Program**
Small food vendors/restaurants pledge their meal-prep capacity without preparing food in advance.
- **How it works:**
  - Vendors register and pledge: "Can prepare X meals, ready in Y minutes, valid for Z hours"
  - System maintains real-time capacity inventory per vendor
  - When order comes, system checks nearest vendor with available capacity
  - Vendor confirms and starts preparation only after order placed
  - Real-time reconciliation: capacity decremented on order, restored on completion/cancellation
  - Vendors set hourly capacity limits and preparation windows (e.g., 8 meals at 11 AM, 10 meals at 12 PM)
  - System sends batch notifications (e.g., "3 orders in your area, prepare now")
  - Vendors receive social recognition badges based on fulfilled pledges
- **Benefits:** Zero food waste, realistic capacity planning, batch efficiency for vendors, faster fulfillment
- **Status:** Fulfillment, handoff, and reconciliation with payment providers are still being refined; the non-negotiable rule remains that SharingBridge does not own financial tracking responsibility.

#### **3. Crowdfunding Orders**
Enable multiple people to contribute to a single order when one person cannot afford it alone.
- **How it works:**
  - Person spots seeker but cannot afford full meal
  - Creates a "request for help" with seeker photo and location
  - Request shared with nearby SharingBridge users
  - Multiple payees contribute small amounts (₹20, ₹50, etc.)
  - Order placed once threshold reached
  - All contributors notified of delivery
- **Benefits:** Lower barrier to giving, community participation, no one turned away
- **Orchestration (TBD):** Threshold logic, refunds, and notifications across contributors are to be designed with the same constraint: no platform-owned financial ledger; money flows stay with providers/vendors.

---

**Document Status:** Business Requirement Document  
**Date:** December 25, 2025  
**Last aligned (operating assumptions):** May 5, 2026  
**Project:** SharingBridge Platform

---

*This platform coordinates affordable meals with accountability and dignity—for beneficiaries, payees, initiators, and vendors—while leveraging existing delivery infrastructure.*
