# **Ketpaar (Seekers) - Digital Alms Platform**

## **Problem Statement**
When encountering people seeking alms, donors face a moral dilemma: offering cash may support unintended uses (substance abuse, exploitation) rather than basic needs like food and shelter. There's no reliable mechanism to ensure charitable donations are used exclusively for essential necessities.

## **Solution**
Ketpaar is a mobile/web application that enables donors to provide food and essential items to alms seekers through verified third-party delivery services, eliminating cash transactions while maintaining dignity and convenience for both parties. **The platform acts as a facilitator only - all payments are processed directly through the vendor's payment system.**

### **Core Workflow:**
1. **Donor Interaction** - Donor engages seeker, obtains consent for food order and identification photo
2. **AI Safety Verification** - System validates delivery location for safety (traffic, lighting, accessibility)
3. **Order Placement** - Integration with external food delivery platforms (Zomato, Swiggy, etc.)
4. **Payment Redirect** - Donor is redirected to vendor's payment gateway; Ketpaar receives order confirmation
5. **Delivery** - Delivery personnel identify seeker using photo, complete handover
6. **Confirmation** - Delivery photo captured and shared with donor for transparency

## **Key Benefits**

**For Donors:**
- Ensures charitable intent is fulfilled (food, medicine, essentials only)
- Provides delivery confirmation with photo proof
- Secure payment through trusted vendor platforms (Zomato, Swiggy, etc.)
- Peace of mind about proper fund utilization
- No financial data shared with Ketpaar

**For Alms Seekers:**
- Guaranteed food/essential items instead of uncertain cash
- Maintains dignity through respectful process
- No exploitation by intermediaries

**For Society:**
- Reduces misuse of charitable funds
- Promotes safe, transparent giving
- Leverages existing delivery infrastructure

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

**3. AI Safety Module**
- Location safety assessment:
  - Traffic density analysis
  - Lighting conditions (time-of-day aware)
  - Public vs isolated area detection
  - Historical delivery success rate
- Duplicate order prevention (same location/hour)
- Delivery crew feedback integration

**4. Integration Layer**
- External food delivery API connectors (Swiggy, Zomato, Uber Eats)
- OAuth/Deep linking for vendor payment redirect
- Webhook listeners for order status updates
- Photo storage (cloud-based)
- Push notification service

**5. Data Management**
- Location coordinates storage
- Photo storage with privacy compliance
- Transaction records
- Safety metrics and analytics

### **Key Technical Features:**
- **AI-powered safety checks** before order confirmation
- **Multi-vendor integration** for wider coverage
- **Photo verification** at both ends (order & delivery)
- **Real-time notifications** for order status
- **Privacy-first design** (encrypted photo storage, limited retention)
- **Payment redirect model** - zero financial liability, no PCI compliance needed
- **Webhook integration** for order tracking without payment handling

### **Technology Stack (Proposed):**
- **Mobile:** React Native / Flutter
- **Backend:** Node.js / Python (Django/FastAPI)
- **AI/ML:** TensorFlow/PyTorch for location safety analysis
- **Database:** PostgreSQL with PostGIS for location data
- **Cloud:** AWS/Azure/GCP
- **APIs:** Food delivery platform APIs

---

**Document Status:** Business Requirement Document
**Date:** December 25, 2025
**Project:** Ketpaar (Seekers) Platform

---

*This platform transforms traditional alms-giving into a modern, accountable, and dignified process that benefits all stakeholders while leveraging existing delivery infrastructure.*
