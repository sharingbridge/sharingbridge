# **ShareBridge - Digital Alms Platform**

## **Problem Statement**
When encountering people seeking alms, donors face a moral dilemma: offering cash may support unintended uses (substance abuse, exploitation) rather than basic needs like food and shelter. There's no reliable mechanism to ensure charitable donations are used exclusively for essential necessities.

## **Solution**
ShareBridge is a mobile/web application that enables donors to provide food and essential items to alms seekers through verified third-party delivery services, eliminating cash transactions while maintaining dignity and convenience for both parties. **The platform acts as a facilitator only - all payments are processed directly through the vendor's payment system.**

### **Core Workflow:**
1. **Location Safety Check** - Donor spots seeker, captures location; AI validates safety before engagement
2. **Beneficiary Assistance History** - System checks whether the beneficiary has recently received support (using photo matching + location proximity) and provides contextual information to the donor without blocking donations
3. **Donor Interaction** - Donor engages seeker, obtains consent for food order and identification photo
4. **Order Placement** - Integration with external food delivery platforms (Zomato, Swiggy, etc.) or direct vendors, with secure beneficiary data sharing via time-limited links or manual instructions
5. **Payment** - For external vendors: redirected to vendor's payment gateway. For direct vendors: Razorpay/Stripe integration (ShareBridge never handles payment directly)
6. **Delivery** - Delivery personnel access secure beneficiary identification data (location, facial description, photo) via one-time NDA-protected links, identify seeker, complete handover, and report completion
7. **Confirmation** - Delivery photo captured and shared with donor for transparency

### **Extended Features:**

#### **1. Pledge Pool System (Advance Donations)**
Donors can pledge money in advance for future seekers they haven't met yet.
- **How it works:**
  - Donors pledge amount (₹100, ₹500, ₹1000, etc.) to a common pool
  - When any donor encounters a seeker, they can use pledged funds instead of paying directly
  - Pledges can be earmarked (location-based, time-based, or general)
  - Real-time dashboard shows pledge utilization
- **Benefits:** Enables giving even when not physically present, creates community fund

#### **2. Direct Vendor Program (Capacity-Based)**
Small food vendors/restaurants pledge their donation capacity without preparing food in advance.
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

#### **3. Crowdfunding Orders (Community Assist)**
Enable multiple people to contribute to a single order when one person cannot afford it alone.
- **How it works:**
  - Person spots seeker but cannot afford full meal
  - Creates a "request for help" with seeker photo and location
  - Request shared with nearby ShareBridge users
  - Multiple donors contribute small amounts (₹20, ₹50, etc.)
  - Order placed once threshold reached
  - All contributors notified of delivery
- **Benefits:** Lower barrier to giving, community participation, no one turned away

## **Key Benefits**

**For Donors:**
- Ensures charitable intent is fulfilled (food, medicine, essentials only)
- Provides delivery confirmation with photo proof
- Secure payment through trusted vendor platforms (Zomato, Swiggy, etc.)
- Peace of mind about proper fund utilization
- No financial data shared with ShareBridge
- Flexible giving options: direct, pledge, or crowdfund
- Community impact visibility

**For Alms Seekers:**
- Guaranteed food/essential items instead of uncertain cash
- Maintains dignity through respectful process
- No exploitation by intermediaries
- Multiple fulfillment options (delivery, vendor pickup, community support)
- Faster access through pledge pools

**For Vendors:**
- Social recognition and community visibility
- CSR (Corporate Social Responsibility) credits
- Direct community engagement without app development costs
- Reduction in food waste through planned donations

**For Society:**
- Reduces misuse of charitable funds
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

**3. AI Safety Module**
- Location safety assessment:
  - Traffic density analysis
  - Lighting conditions (time-of-day aware)
  - Public vs isolated area detection
  - Historical delivery success rate
- Beneficiary assistance history:
  - Facial recognition matching (AI-powered)
  - Location proximity check (within 100m)
  - Time-based filtering (configurable: default 2 hours)
  - Inform donor if beneficiary recently received help
- Delivery crew feedback integration

**4. Integration Layer**
- External food delivery API connectors (Swiggy, Zomato, Uber Eats)
- OAuth/Deep linking for vendor payment redirect
- Webhook listeners for order status updates
- Photo storage (cloud-based)
  - Push notification service (default)
  - In-app notification service (default)
  - Email notification service (default)
  - (Optional/Future) SMS notification service

**5. Data Management**
- Location coordinates storage
- Photo storage with privacy compliance
- Transaction records
- Safety metrics and analytics
- Pledge pool tracking and allocation
- Vendor registry and ratings
- Crowdfunding campaign management
- Community contribution ledger

### **Key Technical Features:**
- **AI-powered safety checks** using external APIs (Google Maps, Places) with rule-based scoring
- **Multi-vendor integration** for wider coverage
- **Photo verification** at both ends (order & delivery)
- **Real-time notifications** for order status (push, in-app, email by default; SMS optional/future)
- **Privacy-first design** (encrypted photo storage, limited retention)
- **Payment delegation** - All payments handled by Razorpay/Stripe or vendor platforms, zero financial liability
- **Webhook integration** for order tracking without payment handling

### **Technology Stack (Proposed):**
- **Mobile:** React Native / Flutter
- **Backend:** Node.js / Python (Django/FastAPI)
- **Safety Assessment:** API-based (Google Maps, Places, OpenWeather) with rule-based scoring; Custom ML optional at scale (5000+ orders/day)
- **Face Recognition:** Pre-trained models (FaceNet/DeepFace) for beneficiary assistance history matching
- **Database:** PostgreSQL with PostGIS for location data
- **Cloud:** AWS/Azure/GCP
- **APIs:** Food delivery platform APIs, Logistics partner APIs (Dunzo/Porter/Shadowfax)

---

**Document Status:** Business Requirement Document
**Date:** December 25, 2025
**Project:** ShareBridge Platform

---

*This platform transforms traditional alms-giving into a modern, accountable, and dignified process that benefits all stakeholders while leveraging existing delivery infrastructure.*
