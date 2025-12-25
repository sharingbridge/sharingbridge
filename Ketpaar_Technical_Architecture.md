# Ketpaar - Technical Architecture Document

**Project:** Ketpaar (கேட்பார்) - Digital Alms Platform  
**Version:** 1.0  
**Date:** December 25, 2025  
**Status:** Design Phase

---

## Table of Contents
1. [System Overview](#system-overview)
2. [Architecture Diagram](#architecture-diagram)
3. [Component Architecture](#component-architecture)
4. [Data Architecture](#data-architecture)
5. [API Design](#api-design)
6. [Security Architecture](#security-architecture)
7. [Integration Architecture](#integration-architecture)
8. [AI/ML Pipeline](#aiml-pipeline)
9. [Deployment Architecture](#deployment-architecture)
10. [Scalability & Performance](#scalability--performance)

---

## 1. System Overview

### 1.1 Architecture Principles
- **Microservices-based** - Loosely coupled services for independent scaling
- **Cloud-native** - Containerized deployment with orchestration
- **API-first** - Well-defined contracts between services
- **Event-driven** - Asynchronous processing for order tracking
- **Zero payment liability** - No financial transaction handling

### 1.2 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     CLIENT LAYER                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ iOS App      │  │ Android App  │  │  Web App     │      │
│  │ (React Native/Flutter)          │  │  (React)     │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                      API GATEWAY                             │
│  (Kong/AWS API Gateway/Azure APIM)                          │
│  - Rate Limiting    - Authentication    - Logging           │
└─────────────────────────────────────────────────────────────┘
                            │
            ┌───────────────┼───────────────┐
            ▼               ▼               ▼
┌──────────────────┐ ┌─────────────┐ ┌─────────────┐
│  Order Service   │ │ AI Safety   │ │   User      │
│                  │ │  Service    │ │  Service    │
└──────────────────┘ └─────────────┘ └─────────────┘
            │               │               │
            ▼               ▼               ▼
┌──────────────────┐ ┌─────────────┐ ┌─────────────┐
│  Integration     │ │  Photo      │ │ Notification│
│   Service        │ │  Service    │ │  Service    │
└──────────────────┘ └─────────────┘ └─────────────┘
            │
            ▼
┌─────────────────────────────────────────────────────────────┐
│              EXTERNAL VENDOR INTEGRATIONS                    │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                  │
│  │  Swiggy  │  │  Zomato  │  │Uber Eats │                  │
│  │   API    │  │   API    │  │   API    │                  │
│  └──────────┘  └──────────┘  └──────────┘                  │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Architecture Diagram

### 2.1 Detailed System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         PRESENTATION LAYER                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌────────────────────────────────────────────────────────┐        │
│  │  Mobile Apps (React Native / Flutter)                  │        │
│  │  - Camera Module    - Location Services                │        │
│  │  - Order Tracking   - Push Notifications               │        │
│  └────────────────────────────────────────────────────────┘        │
│                                                                      │
│  ┌────────────────────────────────────────────────────────┐        │
│  │  Web Application (React/Next.js)                       │        │
│  │  - Responsive Design   - PWA Capabilities              │        │
│  └────────────────────────────────────────────────────────┘        │
│                                                                      │
└──────────────────────────────┬──────────────────────────────────────┘
                               │ HTTPS/REST + WebSockets
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                          API GATEWAY LAYER                           │
├─────────────────────────────────────────────────────────────────────┤
│  Kong / AWS API Gateway / Azure APIM                                │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐               │
│  │ Rate Limit   │ │ Auth (JWT)   │ │  CORS        │               │
│  └──────────────┘ └──────────────┘ └──────────────┘               │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐               │
│  │ Request Log  │ │ Validation   │ │  Routing     │               │
│  └──────────────┘ └──────────────┘ └──────────────┘               │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        BUSINESS LOGIC LAYER                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  USER SERVICE                                               │  │
│  │  - User Registration/Login (OAuth 2.0)                      │  │
│  │  - Profile Management                                       │  │
│  │  - Role Management (Donor, Admin)                           │  │
│  │  - Session Management                                       │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  ORDER SERVICE                                              │  │
│  │  - Order Creation & Validation                              │  │
│  │  - Order State Machine (Created→Validated→Ordered→          │  │
│  │    Confirmed→InTransit→Delivered→Completed)                 │  │
│  │  - Order History & Tracking                                 │  │
│  │  - Duplicate Prevention Logic                               │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  AI SAFETY SERVICE                                          │  │
│  │  - Location Safety Scoring                                  │  │
│  │  - Traffic Analysis (Google Maps API integration)           │  │
│  │  - Time-of-day Safety Assessment                            │  │
│  │  - Historical Data Analysis                                 │  │
│  │  - ML Model Inference                                       │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  PHOTO SERVICE                                              │  │
│  │  - Image Upload & Validation                                │  │
│  │  - Image Compression & Optimization                         │  │
│  │  - Encrypted Storage (S3/Azure Blob)                        │  │
│  │  - Auto-deletion Policy (GDPR compliance)                   │  │
│  │  - Face Detection (optional privacy blur)                   │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  INTEGRATION SERVICE                                        │  │
│  │  - Vendor API Abstraction Layer                             │  │
│  │  - Deep Link Generation (Swiggy/Zomato/Uber Eats)          │  │
│  │  - Order Status Polling/Webhook Handling                    │  │
│  │  - Vendor Response Normalization                            │  │
│  │  - Circuit Breaker Pattern for Fault Tolerance             │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  NOTIFICATION SERVICE                                       │  │
│  │  - Push Notifications (FCM/APNS)                            │  │
│  │  - SMS Notifications (Twilio/AWS SNS)                       │  │
│  │  - Email Notifications                                      │  │
│  │  - In-app Notifications                                     │  │
│  │  - Template Management                                      │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  ANALYTICS SERVICE                                          │  │
│  │  - Order Metrics & KPIs                                     │  │
│  │  - User Behavior Tracking                                   │  │
│  │  - Safety Score Trends                                      │  │
│  │  - Delivery Success Rate                                    │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                      │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         DATA LAYER                                   │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────────────┐  ┌──────────────────┐  ┌─────────────────┐  │
│  │  PostgreSQL      │  │  Redis Cache     │  │  S3/Blob        │  │
│  │  (Primary DB)    │  │  (Session/Cache) │  │  (Photos)       │  │
│  │  + PostGIS       │  │                  │  │                 │  │
│  └──────────────────┘  └──────────────────┘  └─────────────────┘  │
│                                                                      │
│  ┌──────────────────┐  ┌──────────────────┐                        │
│  │  MongoDB/DynamoDB│  │  Elasticsearch   │                        │
│  │  (Order Logs)    │  │  (Search/Logs)   │                        │
│  └──────────────────┘  └──────────────────┘                        │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                      MESSAGE QUEUE LAYER                             │
├─────────────────────────────────────────────────────────────────────┤
│  RabbitMQ / Apache Kafka / AWS SQS                                  │
│  ┌──────────────────┐  ┌──────────────────┐                        │
│  │  Order Events    │  │  Notification    │                        │
│  │  Queue           │  │  Queue           │                        │
│  └──────────────────┘  └──────────────────┘                        │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                    EXTERNAL INTEGRATIONS                             │
├─────────────────────────────────────────────────────────────────────┤
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐               │
│  │  Swiggy API  │ │  Zomato API  │ │Uber Eats API │               │
│  └──────────────┘ └──────────────┘ └──────────────┘               │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐               │
│  │ Google Maps  │ │   FCM/APNS   │ │ Twilio SMS   │               │
│  └──────────────┘ └──────────────┘ └──────────────┘               │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 3. Component Architecture

### 3.1 User Service

**Responsibilities:**
- User authentication and authorization
- Profile management
- Role-based access control (RBAC)

**Technology Stack:**
- Framework: Node.js (Express) or Python (FastAPI)
- Authentication: JWT + OAuth 2.0
- Database: PostgreSQL

**API Endpoints:**
```
POST   /api/v1/auth/register
POST   /api/v1/auth/login
POST   /api/v1/auth/logout
GET    /api/v1/users/profile
PUT    /api/v1/users/profile
GET    /api/v1/users/history
```

**Data Model:**
```sql
users
├── id (UUID, PK)
├── phone_number (VARCHAR, UNIQUE)
├── email (VARCHAR, UNIQUE, NULLABLE)
├── name (VARCHAR)
├── role (ENUM: donor, admin)
├── created_at (TIMESTAMP)
├── updated_at (TIMESTAMP)
├── last_login (TIMESTAMP)
└── is_active (BOOLEAN)
```

---

### 3.2 Order Service

**Responsibilities:**
- Order lifecycle management
- Order validation and business rules
- State machine implementation
- Order history tracking

**Technology Stack:**
- Framework: Node.js (NestJS) or Python (Django)
- Database: PostgreSQL + MongoDB (for event logs)
- Cache: Redis (for active orders)

**Order State Machine:**
```
CREATED → SAFETY_CHECK → VENDOR_SELECTION → 
PAYMENT_REDIRECT → PAYMENT_CONFIRMED → 
IN_TRANSIT → DELIVERED → COMPLETED

Failed states:
→ SAFETY_REJECTED
→ PAYMENT_FAILED
→ DELIVERY_FAILED
→ CANCELLED
```

**API Endpoints:**
```
POST   /api/v1/orders                    # Create new order
GET    /api/v1/orders/:id                # Get order details
GET    /api/v1/orders                    # List orders (with pagination)
PUT    /api/v1/orders/:id/status         # Update order status
POST   /api/v1/orders/:id/photos         # Upload delivery photo
GET    /api/v1/orders/:id/timeline       # Get order event timeline
DELETE /api/v1/orders/:id                # Cancel order
```

**Data Model:**
```sql
orders
├── id (UUID, PK)
├── donor_id (UUID, FK → users.id)
├── status (ENUM)
├── vendor (ENUM: swiggy, zomato, uber_eats)
├── vendor_order_id (VARCHAR)
├── location_lat (DECIMAL)
├── location_lng (DECIMAL)
├── location_address (TEXT)
├── safety_score (DECIMAL)
├── seeker_photo_url (VARCHAR)
├── delivery_photo_url (VARCHAR)
├── total_amount (DECIMAL)
├── items (JSONB)
├── created_at (TIMESTAMP)
├── updated_at (TIMESTAMP)
└── completed_at (TIMESTAMP)

order_events
├── id (UUID, PK)
├── order_id (UUID, FK → orders.id)
├── event_type (VARCHAR)
├── event_data (JSONB)
├── created_at (TIMESTAMP)
└── source (VARCHAR)
```

---

### 3.3 AI Safety Service

**Responsibilities:**
- Location safety assessment
- ML model inference
- Historical data analysis
- Risk scoring

**Technology Stack:**
- Framework: Python (FastAPI)
- ML Framework: TensorFlow/PyTorch
- Model Serving: TensorFlow Serving / TorchServe
- Database: PostgreSQL (historical data)

**Safety Assessment Factors:**

1. **Traffic Analysis**
   - Google Maps Traffic Layer API
   - Real-time traffic density
   - Road type classification

2. **Time-of-Day Assessment**
   - Daylight hours scoring
   - Night-time risk adjustment
   - Peak hours consideration

3. **Location Type**
   - Public vs isolated area
   - Proximity to landmarks
   - Historical delivery success

4. **Historical Data**
   - Previous deliveries at location
   - Success/failure rate
   - Delivery crew feedback

**Safety Score Calculation:**
```python
safety_score = (
    traffic_safety * 0.25 +
    time_of_day_safety * 0.20 +
    location_type_safety * 0.30 +
    historical_success_rate * 0.25
)

# Threshold: >= 0.65 to proceed
```

**API Endpoints:**
```
POST   /api/v1/safety/assess             # Assess location safety
GET    /api/v1/safety/history/:location  # Get historical data
POST   /api/v1/safety/feedback           # Submit delivery feedback
GET    /api/v1/safety/metrics            # Get safety metrics
```

**Data Model:**
```sql
safety_assessments
├── id (UUID, PK)
├── order_id (UUID, FK → orders.id)
├── location_lat (DECIMAL)
├── location_lng (DECIMAL)
├── timestamp (TIMESTAMP)
├── traffic_score (DECIMAL)
├── time_of_day_score (DECIMAL)
├── location_type_score (DECIMAL)
├── historical_score (DECIMAL)
├── final_score (DECIMAL)
├── passed (BOOLEAN)
├── ml_model_version (VARCHAR)
└── assessment_data (JSONB)

delivery_feedback
├── id (UUID, PK)
├── order_id (UUID, FK → orders.id)
├── location_lat (DECIMAL)
├── location_lng (DECIMAL)
├── delivery_success (BOOLEAN)
├── safety_issues (TEXT[])
├── delivery_crew_rating (INTEGER)
├── created_at (TIMESTAMP)
└── feedback_data (JSONB)
```

---

### 3.4 Photo Service

**Responsibilities:**
- Image upload and validation
- Image processing and compression
- Secure storage with encryption
- Auto-deletion for privacy

**Technology Stack:**
- Framework: Node.js or Python
- Storage: AWS S3 / Azure Blob Storage
- Image Processing: Sharp (Node.js) / Pillow (Python)
- CDN: CloudFront / Azure CDN

**Features:**
- Image validation (format, size, content type)
- Compression (reduce file size while maintaining quality)
- Optional face detection for privacy
- Watermarking with order ID
- Encrypted storage at rest
- Time-based auto-deletion (30 days default)

**API Endpoints:**
```
POST   /api/v1/photos/upload             # Upload photo
GET    /api/v1/photos/:id                # Get photo (signed URL)
DELETE /api/v1/photos/:id                # Delete photo
GET    /api/v1/photos/order/:orderId     # Get all photos for order
```

**Data Model:**
```sql
photos
├── id (UUID, PK)
├── order_id (UUID, FK → orders.id)
├── photo_type (ENUM: seeker_identification, delivery_confirmation)
├── storage_url (VARCHAR)
├── file_size (INTEGER)
├── mime_type (VARCHAR)
├── uploaded_by (UUID, FK → users.id)
├── uploaded_at (TIMESTAMP)
├── expires_at (TIMESTAMP)
└── metadata (JSONB)
```

---

### 3.5 Integration Service

**Responsibilities:**
- Vendor API abstraction
- Deep link generation for payment redirect
- Webhook handling for order updates
- Response normalization across vendors

**Technology Stack:**
- Framework: Node.js (Express/NestJS)
- Message Queue: RabbitMQ / AWS SQS
- Cache: Redis (for vendor API tokens)

**Vendor Integration Pattern:**

```javascript
interface VendorAdapter {
  createOrder(orderData: OrderData): Promise<VendorOrder>;
  getOrderStatus(vendorOrderId: string): Promise<OrderStatus>;
  generatePaymentLink(vendorOrderId: string): Promise<string>;
  cancelOrder(vendorOrderId: string): Promise<boolean>;
}

class SwiggyAdapter implements VendorAdapter { ... }
class ZomatoAdapter implements VendorAdapter { ... }
class UberEatsAdapter implements VendorAdapter { ... }
```

**Deep Link Flow:**
1. Ketpaar creates order via vendor API
2. Vendor returns order ID and payment link
3. Ketpaar generates deep link: `ketpaar://order/{orderId}/payment?vendor=swiggy&link={encoded_payment_url}`
4. App opens vendor's payment page (in-app browser or native app)
5. User completes payment on vendor platform
6. Vendor webhook notifies Ketpaar of payment confirmation
7. Ketpaar updates order status and notifies user

**API Endpoints:**
```
POST   /api/v1/vendors/:vendor/orders         # Create vendor order
GET    /api/v1/vendors/:vendor/orders/:id     # Get vendor order status
POST   /api/v1/vendors/webhooks/:vendor       # Vendor webhook handler
GET    /api/v1/vendors/:vendor/menu           # Get vendor menu items
```

**Webhook Signature Verification:**
```python
def verify_webhook(vendor: str, payload: dict, signature: str) -> bool:
    if vendor == 'swiggy':
        return verify_swiggy_signature(payload, signature)
    elif vendor == 'zomato':
        return verify_zomato_signature(payload, signature)
    # ... more vendors
```

---

### 3.6 Notification Service

**Responsibilities:**
- Multi-channel notifications (push, SMS, email)
- Template management
- Notification scheduling and retry logic
- Delivery tracking

**Technology Stack:**
- Framework: Node.js or Python
- Push: Firebase Cloud Messaging (FCM), Apple Push Notification (APNS)
- SMS: Twilio / AWS SNS
- Email: SendGrid / AWS SES
- Queue: RabbitMQ / AWS SQS

**Notification Types:**
```
- Order Created
- Safety Check Passed/Failed
- Payment Link Generated
- Payment Confirmed
- Order In Transit
- Delivery Completed
- Delivery Photo Available
```

**API Endpoints:**
```
POST   /api/v1/notifications/send
GET    /api/v1/notifications/:userId
PUT    /api/v1/notifications/:id/read
GET    /api/v1/notifications/preferences
PUT    /api/v1/notifications/preferences
```

---

## 4. Data Architecture

### 4.1 Database Schema (PostgreSQL)

**Complete Schema:**

```sql
-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone_number VARCHAR(15) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE,
    name VARCHAR(255) NOT NULL,
    role VARCHAR(20) CHECK (role IN ('donor', 'admin')) DEFAULT 'donor',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP,
    is_active BOOLEAN DEFAULT true
);

-- Orders table
CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    donor_id UUID NOT NULL REFERENCES users(id),
    status VARCHAR(50) NOT NULL,
    vendor VARCHAR(20) CHECK (vendor IN ('swiggy', 'zomato', 'uber_eats')),
    vendor_order_id VARCHAR(255),
    location GEOGRAPHY(POINT, 4326) NOT NULL,
    location_address TEXT,
    safety_score DECIMAL(3,2),
    seeker_photo_url VARCHAR(500),
    delivery_photo_url VARCHAR(500),
    total_amount DECIMAL(10,2),
    items JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    metadata JSONB
);

CREATE INDEX idx_orders_donor ON orders(donor_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_location ON orders USING GIST(location);
CREATE INDEX idx_orders_created ON orders(created_at);

-- Order events table
CREATE TABLE order_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    event_type VARCHAR(50) NOT NULL,
    event_data JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    source VARCHAR(50)
);

CREATE INDEX idx_order_events_order ON order_events(order_id);
CREATE INDEX idx_order_events_type ON order_events(event_type);

-- Safety assessments table
CREATE TABLE safety_assessments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES orders(id),
    location GEOGRAPHY(POINT, 4326) NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    traffic_score DECIMAL(3,2),
    time_of_day_score DECIMAL(3,2),
    location_type_score DECIMAL(3,2),
    historical_score DECIMAL(3,2),
    final_score DECIMAL(3,2) NOT NULL,
    passed BOOLEAN NOT NULL,
    ml_model_version VARCHAR(50),
    assessment_data JSONB
);

CREATE INDEX idx_safety_location ON safety_assessments USING GIST(location);
CREATE INDEX idx_safety_timestamp ON safety_assessments(timestamp);

-- Delivery feedback table
CREATE TABLE delivery_feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES orders(id),
    location GEOGRAPHY(POINT, 4326) NOT NULL,
    delivery_success BOOLEAN NOT NULL,
    safety_issues TEXT[],
    delivery_crew_rating INTEGER CHECK (delivery_crew_rating BETWEEN 1 AND 5),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    feedback_data JSONB
);

CREATE INDEX idx_feedback_location ON delivery_feedback USING GIST(location);
CREATE INDEX idx_feedback_success ON delivery_feedback(delivery_success);

-- Photos table
CREATE TABLE photos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    photo_type VARCHAR(30) CHECK (photo_type IN ('seeker_identification', 'delivery_confirmation')),
    storage_url VARCHAR(500) NOT NULL,
    file_size INTEGER,
    mime_type VARCHAR(50),
    uploaded_by UUID REFERENCES users(id),
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    metadata JSONB
);

CREATE INDEX idx_photos_order ON photos(order_id);
CREATE INDEX idx_photos_expires ON photos(expires_at);

-- Notifications table
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    order_id UUID REFERENCES orders(id),
    type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    channel VARCHAR(20) CHECK (channel IN ('push', 'sms', 'email', 'in_app')),
    read BOOLEAN DEFAULT false,
    sent_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_read ON notifications(read);
```

---

### 4.2 Caching Strategy (Redis)

**Cache Keys:**
```
user:session:{userId}           TTL: 24 hours
user:profile:{userId}           TTL: 1 hour
order:active:{orderId}          TTL: 2 hours
vendor:token:{vendor}           TTL: per vendor policy
safety:assessment:{lat}:{lng}   TTL: 30 minutes
rate:limit:{userId}:{endpoint}  TTL: 1 minute
```

**Cache Patterns:**
- **Cache-Aside**: User profiles, order details
- **Write-Through**: Active orders
- **Write-Behind**: Analytics data

---

### 4.3 Message Queue Architecture

**Queue Topics:**
```
ketpaar.orders.created
ketpaar.orders.updated
ketpaar.orders.completed
ketpaar.safety.assessed
ketpaar.photos.uploaded
ketpaar.notifications.send
ketpaar.vendor.webhook
ketpaar.analytics.event
```

**Consumer Services:**
- Notification Service → `ketpaar.notifications.send`
- Analytics Service → `ketpaar.analytics.event`
- Order Service → `ketpaar.vendor.webhook`

---

## 5. API Design

### 5.1 RESTful API Standards

**Base URL:**
```
https://api.ketpaar.com/v1
```

**Authentication:**
```
Authorization: Bearer <JWT_TOKEN>
```

**Response Format:**
```json
{
  "success": true,
  "data": { ... },
  "error": null,
  "metadata": {
    "timestamp": "2025-12-25T10:30:00Z",
    "request_id": "uuid"
  }
}
```

**Error Format:**
```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "SAFETY_CHECK_FAILED",
    "message": "Location safety score too low",
    "details": {
      "safety_score": 0.45,
      "minimum_required": 0.65
    }
  },
  "metadata": { ... }
}
```

---

### 5.2 Complete API Reference

#### **Authentication APIs**

```
POST /api/v1/auth/register
Body: { phone_number, name, email? }
Response: { user, token }

POST /api/v1/auth/login
Body: { phone_number, otp }
Response: { user, token }

POST /api/v1/auth/refresh
Body: { refresh_token }
Response: { token }

POST /api/v1/auth/logout
Headers: Authorization
Response: { success: true }
```

#### **Order APIs**

```
POST /api/v1/orders
Body: {
  location: { lat, lng, address },
  seeker_photo: File,
  items?: [...],
  notes?: string
}
Response: { order_id, status, safety_assessment }

GET /api/v1/orders/:id
Response: { order, timeline, photos }

GET /api/v1/orders?page=1&limit=20&status=completed
Response: { orders[], total, page, limit }

PUT /api/v1/orders/:id/vendor
Body: { vendor: 'swiggy', items: [...] }
Response: { payment_link, vendor_order_id }

POST /api/v1/orders/:id/confirm-payment
Body: { vendor_order_id, payment_reference }
Response: { order, estimated_delivery_time }

POST /api/v1/orders/:id/delivery-photo
Body: { photo: File }
Response: { photo_url }

DELETE /api/v1/orders/:id
Response: { success: true }
```

#### **Safety APIs**

```
POST /api/v1/safety/assess
Body: { lat, lng, timestamp }
Response: {
  safety_score,
  passed,
  breakdown: { traffic, time_of_day, location_type, historical }
}

GET /api/v1/safety/history?lat=&lng=&radius=500
Response: { assessments[], average_score }
```

#### **Photo APIs**

```
POST /api/v1/photos/upload
Body: FormData { photo: File, order_id, photo_type }
Response: { photo_id, url, expires_at }

GET /api/v1/photos/:id
Response: { signed_url, expires_in }
```

#### **User APIs**

```
GET /api/v1/users/profile
Response: { user }

PUT /api/v1/users/profile
Body: { name?, email? }
Response: { user }

GET /api/v1/users/history?page=1&limit=20
Response: { orders[], stats: { total_donations, total_amount } }
```

---

## 6. Security Architecture

### 6.1 Authentication & Authorization

**Authentication Flow:**
```
1. User enters phone number
2. OTP sent via SMS (Twilio)
3. User enters OTP
4. Server validates OTP
5. JWT token issued (access + refresh)
6. Client stores token securely
```

**JWT Structure:**
```json
{
  "sub": "user_id",
  "role": "donor",
  "iat": 1703505600,
  "exp": 1703509200
}
```

**Token Expiry:**
- Access Token: 1 hour
- Refresh Token: 30 days

---

### 6.2 Data Security

**Encryption:**
- **At Rest**: AES-256 encryption for photos in S3/Blob Storage
- **In Transit**: TLS 1.3 for all API communication
- **Database**: PostgreSQL transparent data encryption (TDE)

**PII Protection:**
- Phone numbers hashed for analytics
- Photos auto-deleted after 30 days
- Location data rounded to 100m precision in analytics

**API Security:**
- Rate limiting: 100 requests/minute per user
- DDoS protection via CloudFlare/AWS Shield
- Input validation and sanitization
- SQL injection prevention (parameterized queries)
- XSS prevention (content security policy)

---

### 6.3 Privacy Compliance (GDPR/DPDPA)

**User Rights:**
- Right to access data (export API)
- Right to deletion (account deletion + data purge)
- Right to portability (JSON export)

**Data Retention:**
- Active orders: Indefinite
- Completed orders: 90 days (configurable)
- Photos: 30 days (auto-deletion)
- Logs: 180 days

**Consent Management:**
- Photo capture consent (explicit)
- Location tracking consent
- SMS/Push notification consent

---

## 7. Integration Architecture

### 7.1 Food Delivery Vendor Integration

**Integration Methods:**

**Option 1: REST API Integration**
```
- Direct API calls to vendor endpoints
- OAuth 2.0 authentication
- Webhook for order updates
```

**Option 2: Deep Link Integration**
```
- Generate vendor-specific deep links
- Redirect user to vendor app/website
- Callback URL for payment confirmation
```

**Vendor Adapter Pattern:**

```typescript
interface VendorConfig {
  name: string;
  apiBaseUrl: string;
  authMethod: 'oauth' | 'api_key';
  webhookSecret: string;
  deepLinkSchema: string;
}

class VendorService {
  private adapters: Map<string, VendorAdapter>;
  
  async createOrder(vendor: string, orderData: OrderData) {
    const adapter = this.adapters.get(vendor);
    return await adapter.createOrder(orderData);
  }
  
  async getStatus(vendor: string, vendorOrderId: string) {
    const adapter = this.adapters.get(vendor);
    return await adapter.getOrderStatus(vendorOrderId);
  }
}
```

**Webhook Handling:**
```typescript
@Post('/vendors/webhooks/:vendor')
async handleWebhook(
  @Param('vendor') vendor: string,
  @Body() payload: any,
  @Headers('signature') signature: string
) {
  // Verify signature
  if (!this.verifySignature(vendor, payload, signature)) {
    throw new UnauthorizedException();
  }
  
  // Normalize webhook data
  const orderUpdate = this.normalizeWebhookData(vendor, payload);
  
  // Update order status
  await this.orderService.updateStatus(
    orderUpdate.orderId,
    orderUpdate.status
  );
  
  // Send notification
  await this.notificationService.send({
    userId: orderUpdate.userId,
    type: 'order_update',
    data: orderUpdate
  });
}
```

---

### 7.2 Google Maps Integration

**Usage:**
- Location geocoding
- Reverse geocoding (address from coordinates)
- Traffic data API
- Places API (for location type detection)

**API Calls:**
```javascript
// Traffic assessment
const trafficData = await googleMaps.roads.nearestRoads({
  points: `${lat},${lng}`,
});

// Place type detection
const placeData = await googleMaps.places.nearbySearch({
  location: { lat, lng },
  radius: 100,
});
```

---

### 7.3 Third-Party Services

| Service | Purpose | Provider Options |
|---------|---------|-----------------|
| SMS | OTP delivery | Twilio, AWS SNS, Gupshup |
| Push Notifications | Real-time updates | Firebase FCM, APNS |
| Email | Receipts, updates | SendGrid, AWS SES |
| Storage | Photo storage | AWS S3, Azure Blob, GCP Storage |
| Maps | Location services | Google Maps, Mapbox |
| Analytics | Usage tracking | Google Analytics, Mixpanel |
| Monitoring | APM | DataDog, New Relic, Sentry |

---

## 8. AI/ML Pipeline

### 8.1 Safety Assessment Model

**Model Architecture:**
```
Input Features (12 dimensions):
├── Location coordinates (lat, lng)
├── Time of day (hour, day_of_week)
├── Traffic density score
├── Road type classification
├── Proximity to public places
├── Historical delivery success rate
├── Weather conditions
└── Lighting conditions

Model: Random Forest Classifier / Gradient Boosting
Output: Safety score (0.0 - 1.0)
Threshold: >= 0.65 for approval
```

**Training Pipeline:**
```python
# Feature engineering
features = [
    'hour_of_day',
    'day_of_week',
    'traffic_density',
    'road_type',
    'distance_to_landmark',
    'historical_success_rate',
    'weather_score',
    'lighting_score',
    'is_residential',
    'is_commercial',
    'population_density',
    'crime_rate'
]

# Model training
model = GradientBoostingClassifier(
    n_estimators=100,
    max_depth=5,
    learning_rate=0.1
)

model.fit(X_train, y_train)
```

**Model Deployment:**
- Model versioning with MLflow
- A/B testing for model updates
- Fallback to rule-based system if ML service down
- Model retraining every 30 days with new data

---

### 8.2 Image Processing Pipeline

**Seeker Photo Processing:**
```python
def process_seeker_photo(image_file):
    # 1. Validate format and size
    validate_image(image_file)
    
    # 2. Compress image
    compressed = compress_image(image_file, max_size=500KB)
    
    # 3. Optional: Face detection
    faces = detect_faces(compressed)
    
    # 4. Watermark with order ID
    watermarked = add_watermark(compressed, order_id)
    
    # 5. Encrypt and upload
    encrypted = encrypt_image(watermarked)
    url = upload_to_s3(encrypted, bucket='ketpaar-photos')
    
    return url
```

---

## 9. Deployment Architecture

### 9.1 Cloud Infrastructure (AWS Example)

```
┌─────────────────────────────────────────────────────────┐
│                    Route 53 (DNS)                        │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│              CloudFront (CDN)                            │
│              + WAF (DDoS Protection)                     │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│         Application Load Balancer (ALB)                  │
│         - SSL Termination                                │
│         - Health Checks                                  │
└────────────────────┬────────────────────────────────────┘
                     │
        ┌────────────┼────────────┐
        ▼            ▼            ▼
┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│   ECS/EKS   │ │   ECS/EKS   │ │   ECS/EKS   │
│  Cluster 1  │ │  Cluster 2  │ │  Cluster 3  │
│ (Multi-AZ)  │ │ (Multi-AZ)  │ │ (Multi-AZ)  │
└─────────────┘ └─────────────┘ └─────────────┘

Data Layer:
┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│  RDS        │ │ ElastiCache │ │     S3      │
│ PostgreSQL  │ │   (Redis)   │ │  (Photos)   │
│ Multi-AZ    │ │  Cluster    │ │             │
└─────────────┘ └─────────────┘ └─────────────┘

Message Queue:
┌─────────────┐ ┌─────────────┐
│     SQS     │ │     SNS     │
│  (Queues)   │ │ (Pub/Sub)   │
└─────────────┘ └─────────────┘

Monitoring:
┌─────────────┐ ┌─────────────┐
│ CloudWatch  │ │   X-Ray     │
│  (Metrics)  │ │  (Tracing)  │
└─────────────┘ └─────────────┘
```

---

### 9.2 Container Architecture (Kubernetes)

**Deployment Manifests:**

```yaml
# Order Service Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-service
spec:
  replicas: 3
  selector:
    matchLabels:
      app: order-service
  template:
    metadata:
      labels:
        app: order-service
    spec:
      containers:
      - name: order-service
        image: ketpaar/order-service:1.0.0
        ports:
        - containerPort: 3000
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: db-secrets
              key: url
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
```

---

### 9.3 CI/CD Pipeline

**Pipeline Stages:**

```
┌──────────────┐
│ Code Commit  │
│  (GitHub)    │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Build        │
│ (GitHub      │
│  Actions)    │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Test         │
│ - Unit       │
│ - Integration│
│ - E2E        │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Security     │
│ Scan         │
│ (Snyk)       │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Build Docker │
│ Image        │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Push to ECR  │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Deploy to    │
│ Staging      │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Smoke Tests  │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Manual       │
│ Approval     │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Deploy to    │
│ Production   │
└──────────────┘
```

---

## 10. Scalability & Performance

### 10.1 Horizontal Scaling Strategy

**Auto-scaling Rules:**
```yaml
# Order Service Auto-scaling
CPU > 70% → Scale up (+2 pods)
CPU < 30% → Scale down (-1 pod)
Min replicas: 2
Max replicas: 10

# AI Safety Service Auto-scaling
Queue depth > 100 → Scale up (+1 pod)
Queue depth < 20 → Scale down (-1 pod)
Min replicas: 1
Max replicas: 5
```

---

### 10.2 Performance Targets

| Metric | Target | Measurement |
|--------|--------|-------------|
| API Response Time (p95) | < 200ms | Load balancer metrics |
| API Response Time (p99) | < 500ms | Load balancer metrics |
| Safety Assessment | < 2s | Service-level metric |
| Photo Upload | < 5s | End-to-end |
| Order Creation | < 3s | End-to-end |
| Database Query (p95) | < 50ms | PostgreSQL metrics |
| Cache Hit Rate | > 80% | Redis metrics |
| Uptime | 99.9% | Monthly average |

---

### 10.3 Database Optimization

**Indexing Strategy:**
- B-tree indexes on foreign keys
- GiST indexes on geography columns
- Partial indexes on active orders
- Covering indexes for common queries

**Query Optimization:**
- Connection pooling (PgBouncer)
- Read replicas for analytics queries
- Materialized views for dashboards
- Query result caching

**Partitioning:**
```sql
-- Partition orders by month
CREATE TABLE orders_2025_12 PARTITION OF orders
FOR VALUES FROM ('2025-12-01') TO ('2026-01-01');
```

---

### 10.4 Caching Strategy

**Multi-level Caching:**
```
L1: Application-level cache (in-memory)
L2: Redis cache (distributed)
L3: CDN cache (static assets)
```

**Cache Invalidation:**
- Time-based expiry (TTL)
- Event-based invalidation (order updates)
- Manual purge via admin API

---

## 11. Monitoring & Observability

### 11.1 Metrics

**Application Metrics:**
- Request rate (requests/second)
- Error rate (errors/total requests)
- Latency (p50, p95, p99)
- Active users
- Orders created/hour
- Safety check pass rate

**Infrastructure Metrics:**
- CPU usage
- Memory usage
- Disk I/O
- Network throughput
- Container restarts

**Business Metrics:**
- Total orders
- Average order value
- Vendor distribution
- Delivery success rate
- User retention

---

### 11.2 Logging

**Log Levels:**
- ERROR: Application errors
- WARN: Degraded performance
- INFO: Important events
- DEBUG: Detailed debugging

**Structured Logging:**
```json
{
  "timestamp": "2025-12-25T10:30:00Z",
  "level": "INFO",
  "service": "order-service",
  "request_id": "uuid",
  "user_id": "uuid",
  "event": "order_created",
  "data": {
    "order_id": "uuid",
    "vendor": "swiggy"
  }
}
```

**Log Aggregation:**
- ELK Stack (Elasticsearch, Logstash, Kibana)
- CloudWatch Logs (AWS)
- Azure Monitor (Azure)

---

### 11.3 Alerting

**Alert Rules:**
```
Critical:
- Service down (5xx > 50% for 5 min)
- Database connection pool exhausted
- Disk usage > 90%

Warning:
- High latency (p95 > 500ms for 10 min)
- Cache miss rate > 40%
- Queue depth > 1000
```

**Alert Channels:**
- PagerDuty (critical)
- Slack (warnings)
- Email (daily summaries)

---

## 12. Disaster Recovery & Business Continuity

### 12.1 Backup Strategy

**Database Backups:**
- Automated daily backups
- Point-in-time recovery (35 days)
- Cross-region replication
- Backup retention: 90 days

**Photo Backups:**
- S3 versioning enabled
- Cross-region replication
- Lifecycle policy (30 days hot, then glacier)

---

### 12.2 Disaster Recovery Plan

**RTO/RPO Targets:**
- Recovery Time Objective (RTO): 4 hours
- Recovery Point Objective (RPO): 1 hour

**DR Procedures:**
1. Activate standby region
2. Promote read replica to master
3. Update DNS to point to DR region
4. Verify application functionality
5. Monitor system health

---

## Appendix

### Technology Decision Matrix

| Component | Options Evaluated | Selected | Rationale |
|-----------|------------------|----------|-----------|
| Mobile Framework | Native, React Native, Flutter | **React Native** | Single codebase, large community, mature ecosystem |
| Backend Framework | Express, NestJS, Django, FastAPI | **NestJS** | TypeScript, modular, enterprise-ready |
| Database | PostgreSQL, MySQL, MongoDB | **PostgreSQL** | PostGIS for geospatial, JSONB support, reliability |
| Cache | Redis, Memcached | **Redis** | Pub/Sub, data structures, persistence |
| Message Queue | RabbitMQ, Kafka, SQS | **RabbitMQ** | Simplicity, low latency, good for event-driven |
| Cloud Provider | AWS, Azure, GCP | **AWS** | Market leader, comprehensive services, community |
| Container Orchestration | ECS, EKS, Kubernetes | **EKS** | Standard Kubernetes, portability, ecosystem |

---

**Document Status:** Draft v1.0  
**Next Review:** Q1 2026  
**Owner:** Ketpaar Engineering Team

---

*This technical architecture is designed to be scalable, maintainable, and aligned with modern cloud-native best practices.*
