# ShareBridge - Technical Architecture Document

**Project:** ShareBridge - Digital Alms Platform  
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
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  PLEDGE SERVICE                                             │  │
│  │  - Pledge Creation & Management                             │  │
│  │  - Pledge Pool Allocation                                   │  │
│  │  - Auto-deduction for Orders                                │  │
│  │  - Pledge History & Analytics                               │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  VENDOR SERVICE                                             │  │
│  │  - Vendor Registration & Verification                       │  │
│  │  - Menu Management                                          │  │
│  │  - Direct Donation Scheduling                               │  │
│  │  - Rating & Recognition System                              │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  CROWDFUNDING SERVICE                                       │  │
│  │  - Campaign Creation & Management                           │  │
│  │  - Multi-donor Contribution Handling                        │  │
│  │  - Threshold Monitoring & Order Trigger                     │  │
│  │  - Contributor Notification                                 │  │
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
├── donation_type (ENUM: food, cloth, shelter, blanket, mosquito_net, washroom_access, miscellaneous)
├── vendor (ENUM: swiggy, zomato, uber_eats, NULLABLE)
├── vendor_order_id (VARCHAR)
├── location (GEOGRAPHY(POINT, 4326))
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

5. **Duplicate Seeker Detection (Informational Only - Non-Blocking)**
   - Facial recognition using ML (compare with recent orders)
   - Location proximity matching (within configurable radius)
   - Time window check (default: 2 hours - more lenient for edge cases)
   - Last order status and donation type checking
   - Returns: duplicate probability score + recent order details + donor-friendly information
   - Lenient thresholds to accommodate lighting, angle, and appearance variations
   - **Important: NEVER blocks donations - only provides context to donors**
   - Donors make final decision based on their judgment and compassion

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

**Duplicate Seeker Detection Algorithm:**
```python
import numpy as np
from datetime import datetime, timedelta

class DuplicateSeekerDetector:
    DUPLICATE_WINDOW_HOURS = 2  # Configurable
    LOCATION_RADIUS_METERS = 150  # Increased for leniency
    SIMILARITY_THRESHOLD = 0.78  # For detecting possible matches
    CONFIDENCE_THRESHOLD_HIGH = 0.85  # High confidence match
    CONFIDENCE_THRESHOLD_MEDIUM = 0.78  # Medium confidence match
    
    async def check_duplicate(self, photo, location, timestamp, donor_id=None):
        # 1. Extract facial embedding from photo
        face_embedding = await self.extract_face_embedding(photo)
        
        if face_embedding is None:
            return {
                'is_duplicate': False,
                'confidence': 'low',
                'message': 'No clear face detected',
                'donor_message': 'ℹ️ Face not clearly detected in photo. You may still proceed with your donation.',
                'show_to_donor': False  # Don't show if no face detected
            }
        
        # 2. Find recent orders in proximity
        time_threshold = timestamp - timedelta(hours=self.DUPLICATE_WINDOW_HOURS)
        
        recent_seekers = await SeekerDetection.objects.filter(
            timestamp__gte=time_threshold,
            location__dwithin=(location, self.LOCATION_RADIUS_METERS)
        ).all()
        
        # 3. Compare face embeddings with lenient matching
        best_match = None
        best_similarity = 0
        
        for seeker in recent_seekers:
            similarity = self.cosine_similarity(
                face_embedding, 
                seeker.face_embedding
            )
            
            if similarity > best_similarity:
                best_similarity = similarity
                best_match = seeker
        
        # 4. Process best match - provide informational context only
        if best_match and best_similarity >= self.SIMILARITY_THRESHOLD:
            order_details = await Order.objects.get(id=best_match.order_id)
            time_ago_minutes = (timestamp - best_match.timestamp).seconds // 60
            distance_meters = self.calculate_distance(location, best_match.location)
            
            # Determine confidence level for informational purposes
            is_high_confidence = best_similarity >= self.CONFIDENCE_THRESHOLD_HIGH
            
            # Build donor-friendly informational message
            donor_message = self._build_donor_message(
                order_details, time_ago_minutes, distance_meters, 
                best_similarity
            )
            
            return {
                'is_duplicate': is_high_confidence,
                'is_possible_duplicate': best_similarity >= self.SIMILARITY_THRESHOLD,
                'confidence': 'high' if is_high_confidence else 'medium',
                'similarity_score': best_similarity,
                'previous_order': {
                    'order_id': best_match.order_id,
                    'status': order_details.status,
                    'donation_type': order_details.donation_type,
                    'timestamp': best_match.timestamp,
                    'time_ago_minutes': time_ago_minutes,
                    'distance_meters': distance_meters
                },
                'message': f'Possible match found - {time_ago_minutes} minutes ago',
                'donor_message': donor_message,
                'show_to_donor': True  # Show info to donor for their awareness
            }
        
        # 5. No duplicate found
        return {
            'is_duplicate': False,
            'is_possible_duplicate': False,
            'confidence': 'high',
            'message': 'No recent help detected for this seeker',
            'donor_message': 'ℹ️ No recent donations found for this person in the area.',
            'show_to_donor': False  # No need to show if no duplicate
        }
    
    def _build_donor_message(self, order, time_ago, distance, similarity):
        """Build human-friendly informational message for donor (non-blocking)"""
        status_text = {
            'pending': 'is being processed',
            'confirmed': 'was confirmed',
            'in_progress': 'is in delivery',
            'completed': 'was successfully delivered',
            'cancelled': 'was cancelled'
        }.get(order.status, 'exists')
        
        type_text = {
            'food': 'food',
            'cloth': 'clothing',
            'shelter': 'shelter',
            'blanket': 'blanket(s)',
            'mosquito_net': 'mosquito net',
            'washroom_access': 'washroom access',
            'miscellaneous': 'assistance'
        }.get(order.donation_type, 'help')
        
        confidence_text = 'likely' if similarity >= 0.85 else 'possibly'
        
        # Informational message without blocking suggestions
        message = f"ℹ️ **For Your Information**\n\n"
        message += f"This person {confidence_text} received {type_text} {time_ago} minutes ago (~{distance}m away).\n"
        message += f"Previous order {status_text}.\n\n"
        message += f"💙 **You can still proceed with your donation.** This information is provided for context only. "
        message += f"There may be legitimate reasons for multiple requests (different needs, family members, etc.)."
        
        return message
    
    def cosine_similarity(self, embedding1, embedding2):
        return np.dot(embedding1, embedding2) / (
            np.linalg.norm(embedding1) * np.linalg.norm(embedding2)
        )
    
    async def extract_face_embedding(self, photo):
        """Use face recognition model (e.g., FaceNet, DeepFace)"""
        # Implementation using TensorFlow/PyTorch model
        # Returns 128-dimensional embedding vector
        pass
```

**API Endpoints:**
```
POST   /api/v1/safety/assess             # Assess location safety
POST   /api/v1/safety/check-duplicate    # Check for duplicate seeker (informational only)
GET    /api/v1/safety/history/:location  # Get historical data
POST   /api/v1/safety/feedback           # Submit delivery feedback
GET    /api/v1/safety/metrics            # Get safety metrics
```

**Data Model:**
```sql
safety_assessments
├── id (UUID, PK)
├── order_id (UUID, FK → orders.id)
├── location (GEOGRAPHY(POINT, 4326))
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
├── location (GEOGRAPHY(POINT, 4326))
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
- Vendor API abstraction (food delivery platforms)
- Logistics partner API abstraction (for pledged vendor deliveries)
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

// Food delivery platforms (includes delivery)
class SwiggyAdapter implements VendorAdapter { ... }
class ZomatoAdapter implements VendorAdapter { ... }
class UberEatsAdapter implements VendorAdapter { ... }

// Logistics partners (for pledged vendor orders)
interface LogisticsAdapter {
  createDelivery(pickupLocation: Location, dropLocation: Location, orderId: string): Promise<DeliveryTask>;
  getDeliveryStatus(taskId: string): Promise<DeliveryStatus>;
  cancelDelivery(taskId: string): Promise<boolean>;
  trackDelivery(taskId: string): Promise<LiveTracking>;
}

class DunzoAdapter implements LogisticsAdapter { ... }
class PorterAdapter implements LogisticsAdapter { ... }
class ShadowfaxAdapter implements LogisticsAdapter { ... }
```

**Deep Link Flow (External Vendors - Swiggy/Zomato/UberEats):**
1. ShareBridge creates order via vendor API
2. Vendor returns order ID and payment link
3. ShareBridge generates deep link: `ShareBridge://order/{orderId}/payment?vendor=swiggy&link={encoded_payment_url}`
4. App opens vendor's payment page (in-app browser or native app)
5. User completes payment on vendor platform
6. Vendor webhook notifies ShareBridge of payment confirmation
7. Vendor's delivery fleet handles pickup and delivery to seeker
8. ShareBridge tracks status updates via webhook

**Logistics Flow (Pledged Vendors - Direct Orders):**
1. Donor pays via ShareBridge payment gateway (Razorpay/Stripe)
2. Order sent to pledged vendor (restaurant/home kitchen)
3. Vendor prepares food and marks order as READY
4. ShareBridge automatically triggers logistics partner API (Dunzo/Porter/Shadowfax)
5. Logistics partner assigns delivery executive for pickup
6. Delivery executive picks up from vendor and delivers to seeker
7. Delivery confirmation with photo upload
8. Status updates tracked in real-time

**API Endpoints:**
```
# External vendor integration
POST   /api/v1/vendors/:vendor/orders         # Create vendor order
GET    /api/v1/vendors/:vendor/orders/:id     # Get vendor order status
POST   /api/v1/vendors/webhooks/:vendor       # Vendor webhook handler
GET    /api/v1/vendors/:vendor/menu           # Get vendor menu items

# Logistics partner integration
POST   /api/v1/logistics/:provider/delivery   # Create delivery task
GET    /api/v1/logistics/:provider/task/:id   # Get delivery status
POST   /api/v1/logistics/webhooks/:provider   # Logistics webhook handler
DELETE /api/v1/logistics/:provider/task/:id   # Cancel delivery
GET    /api/v1/logistics/:provider/track/:id  # Live tracking
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

### 3.7 Pledge Service

**Responsibilities:**
- Manage advance donations/pledges
- Allocate pledged funds to orders
- Track pledge utilization
- Generate pledge analytics

**Technology Stack:**
- Framework: Node.js (NestJS) or Python (Django)
- Database: PostgreSQL
- Cache: Redis (for quick allocation)

**Pledge Types:**
```
1. General Pledge: Available for any seeker, anywhere
2. Location-based: Within specific radius (e.g., my neighborhood)
3. Time-based: Valid during specific hours (e.g., lunch time)
4. Amount-based: Auto-renew monthly pledges
```

**Allocation Algorithm:**
```python
def allocate_pledge(order_amount, location, timestamp):
    # Priority order:
    # 1. Location + Time specific pledges
    # 2. Location-specific pledges
    # 3. Time-specific pledges
    # 4. General pledges (oldest first)
    
    allocated = []
    remaining = order_amount
    
    for pledge in get_matching_pledges(location, timestamp):
        if remaining <= 0:
            break
        amount_to_use = min(pledge.available_amount, remaining)
        allocated.append({
            'pledge_id': pledge.id,
            'amount': amount_to_use
        })
        remaining -= amount_to_use
    
    return allocated, remaining
```

**API Endpoints:**
```
POST   /api/v1/pledges                    # Create new pledge
GET    /api/v1/pledges                    # List user's pledges
GET    /api/v1/pledges/:id                # Get pledge details
PUT    /api/v1/pledges/:id                # Update pledge
DELETE /api/v1/pledges/:id                # Cancel pledge
GET    /api/v1/pledges/pool               # Get pledge pool stats
GET    /api/v1/pledges/:id/utilization    # Get utilization history
POST   /api/v1/orders/:id/use-pledge      # Use pledge for order
```

**Data Model:**
```sql
pledges
├── id (UUID, PK)
├── donor_id (UUID, FK → users.id)
├── total_amount (DECIMAL)
├── remaining_amount (DECIMAL)
├── pledge_type (ENUM: general, location_based, time_based)
├── location (GEOGRAPHY, NULLABLE)
├── radius_meters (INTEGER, NULLABLE)
├── valid_from_hour (INTEGER, NULLABLE)
├── valid_to_hour (INTEGER, NULLABLE)
├── auto_renew (BOOLEAN)
├── status (ENUM: active, depleted, cancelled)
├── created_at (TIMESTAMP)
├── expires_at (TIMESTAMP, NULLABLE)
└── metadata (JSONB)

pledge_allocations
├── id (UUID, PK)
├── pledge_id (UUID, FK → pledges.id)
├── order_id (UUID, FK → orders.id)
├── amount_used (DECIMAL)
├── allocated_at (TIMESTAMP)
└── status (ENUM: allocated, used, refunded)
```

---

### 3.8 Vendor Service

**Responsibilities:**
- Vendor registration and verification
- Menu and availability management
- Direct donation order handling
- Vendor rating and recognition

**Technology Stack:**
- Framework: Node.js or Python
- Database: PostgreSQL
- Storage: S3 (vendor photos, documents)

**Vendor Types:**
```
1. Registered Restaurant: Has all licenses, verified
2. Home Kitchen: Smaller scale, community verified
3. Food Truck: Mobile vendors
4. NGO Kitchen: Charity organizations
```

**Capacity Pledge Model:**
```
Vendors pledge hourly donation capacity, not prepared food:
- Hourly capacity: "Can prepare 5-10 meals per hour"
- Time slots: Hourly slots during active hours (e.g., 11 AM, 12 PM, 1 PM, 2 PM)
- Active hours: "11:00 AM - 2:00 PM, 6:00 PM - 9:00 PM"
- Preparation time: "30 minutes from order to ready"
- Menu items: Limited selection for efficiency

Example: Restaurant pledges:
  - 11:00-12:00: 8 meals
  - 12:00-13:00: 10 meals
  - 13:00-14:00: 8 meals
  - 18:00-19:00: 12 meals
  - 19:00-20:00: 15 meals
  - 20:00-21:00: 10 meals

Real-time Inventory:
- Hourly capacity decremented on order placement for that time slot
- Orders assigned to current or next available hour
- Capacity restored on cancellation within the same hour
- Prevents rush hour overload
- Enables even distribution of orders
- Batch preparation within each hour slot

Delivery Logistics:
- Vendors prepare food; delivery handled by logistics partners
- Automatic integration with Dunzo/Porter/Shadowfax
- When vendor marks order READY, delivery auto-triggered
- Pickup from vendor location, delivery to seeker location
- Real-time tracking and status updates
- Delivery cost included in order total or subsidized
```

**Verification Process:**
```
1. Vendor submits registration
2. Documents uploaded (FSSAI license, etc.)
3. Admin review
4. Field verification (optional)
5. Approval & badge assignment
6. Capacity & menu setup
7. Go live with pledged capacity
```

**API Endpoints:**
```
POST   /api/v1/vendors/register           # Vendor registration
GET    /api/v1/vendors                    # List vendors (with filters)
GET    /api/v1/vendors/:id                # Get vendor details
PUT    /api/v1/vendors/:id                # Update vendor profile
POST   /api/v1/vendors/:id/menu           # Add/update menu items
GET    /api/v1/vendors/:id/menu           # Get vendor menu
POST   /api/v1/vendors/:id/capacity/hourly # Set hourly capacity pledge
PUT    /api/v1/vendors/:id/capacity/hourly/:date # Update hourly capacity for date
GET    /api/v1/vendors/:id/capacity/hourly?date=YYYY-MM-DD # Get hourly capacity
GET    /api/v1/vendors/:id/capacity/available # Get available slots for today
POST   /api/v1/vendors/:id/orders         # Receive order notification
PUT    /api/v1/vendors/:id/orders/:orderId # Update order status (preparing/ready)
GET    /api/v1/vendors/:id/donations      # List donation history
PUT    /api/v1/vendors/:id/availability   # Update availability
GET    /api/v1/vendors/nearby?lat=&lng=&hour=14 # Find vendors with capacity at hour
POST   /api/v1/vendors/:id/ratings        # Rate vendor
GET    /api/v1/vendors/:id/reconciliation?date=YYYY-MM-DD # Hourly reconciliation
```

**Data Model:**
```sql
vendors
├── id (UUID, PK)
├── owner_id (UUID, FK → users.id)
├── business_name (VARCHAR)
├── vendor_type (ENUM)
├── location (GEOGRAPHY)
├── address (TEXT)
├── phone (VARCHAR)
├── email (VARCHAR)
├── fssai_license (VARCHAR)
├── verification_status (ENUM: pending, verified, rejected)
├── rating (DECIMAL)
├── total_donations (INTEGER)
├── recognition_badge (VARCHAR, NULLABLE)
├── is_active (BOOLEAN)
├── created_at (TIMESTAMP)
└── metadata (JSONB)

vendor_capacity_hourly
├── id (UUID, PK)
├── vendor_id (UUID, FK → vendors.id)
├── date (DATE)
├── hour (INTEGER) -- Hour of the day (0-23)
├── total_hourly_capacity (INTEGER) -- Max orders for this hour
├── remaining_capacity (INTEGER) -- Available orders for this hour
├── preparation_time_minutes (INTEGER)
├── batch_size (INTEGER) -- Optimal batch size for efficiency
├── is_active (BOOLEAN) -- Whether vendor accepts orders this hour
├── last_updated (TIMESTAMP)
└── UNIQUE(vendor_id, date, hour)

vendor_menu_items
├── id (UUID, PK)
├── vendor_id (UUID, FK → vendors.id)
├── item_name (VARCHAR)
├── description (TEXT)
├── category (VARCHAR)
├── is_available (BOOLEAN)
├── preparation_time (INTEGER)
└── created_at (TIMESTAMP)

vendor_orders
├── id (UUID, PK)
├── vendor_id (UUID, FK → vendors.id)
├── order_id (UUID, FK → orders.id)
├── assigned_date (DATE) -- Date for which capacity is reserved
├── assigned_hour (INTEGER) -- Hour slot (0-23) for preparation
├── capacity_reserved_at (TIMESTAMP)
├── preparation_started_at (TIMESTAMP, NULLABLE)
├── ready_at (TIMESTAMP, NULLABLE)
├── completed_at (TIMESTAMP, NULLABLE)
├── status (ENUM: reserved, preparing, ready, picked_up, delivered, cancelled)
└── metadata (JSONB)

vendor_capacity_log
├── id (UUID, PK)
├── vendor_id (UUID, FK → vendors.id)
├── date (DATE)
├── hour (INTEGER) -- Hour of the day (0-23)
├── order_id (UUID, FK → orders.id, NULLABLE)
├── action (ENUM: reserve, release, complete, cancel)
├── capacity_change (INTEGER) -- negative for reserve, positive for release
├── remaining_after (INTEGER)
├── timestamp (TIMESTAMP)
└── reason (VARCHAR)

vendor_ratings
├── id (UUID, PK)
├── vendor_id (UUID, FK → vendors.id)
├── order_id (UUID, FK → orders.id)
├── user_id (UUID, FK → users.id)
├── rating (INTEGER CHECK 1-5)
├── comment (TEXT)
├── created_at (TIMESTAMP)

CREATE INDEX idx_vendor_capacity_hourly ON vendor_capacity_hourly(vendor_id, date, hour);
CREATE INDEX idx_vendor_capacity_available ON vendor_capacity_hourly(vendor_id, date) WHERE remaining_capacity > 0 AND is_active = true;
CREATE INDEX idx_vendor_orders_status ON vendor_orders(vendor_id, status);
CREATE INDEX idx_vendor_orders_slot ON vendor_orders(vendor_id, assigned_date, assigned_hour);
```

**Capacity Management Algorithm:**
```python
from datetime import datetime, timedelta

class VendorCapacityManager:
    def find_available_slot(self, vendor_id: UUID, current_time: datetime) -> Optional[tuple[date, int]]:
        """Find next available hour slot with capacity"""
        current_date = current_time.date()
        current_hour = current_time.hour
        
        # Check current hour and next 12 hours
        for hour_offset in range(13):
            check_time = current_time + timedelta(hours=hour_offset)
            check_date = check_time.date()
            check_hour = check_time.hour
            
            slot = VendorCapacityHourly.objects.filter(
                vendor_id=vendor_id,
                date=check_date,
                hour=check_hour,
                is_active=True,
                remaining_capacity__gt=0
            ).first()
            
            if slot:
                return (check_date, check_hour)
        
        return None
    
    def reserve_capacity(self, vendor_id: UUID, date: date, hour: int, quantity: int = 1) -> bool:
        """Reserve capacity for specific hour with pessimistic locking"""
        with transaction():
            capacity = VendorCapacityHourly.objects.select_for_update().get(
                vendor_id=vendor_id,
                date=date,
                hour=hour
            )
            
            if capacity.is_active and capacity.remaining_capacity >= quantity:
                capacity.remaining_capacity -= quantity
                capacity.last_updated = datetime.now()
                capacity.save()
                
                # Log transaction
                VendorCapacityLog.objects.create(
                    vendor_id=vendor_id,
                    date=date,
                    hour=hour,
                    action='reserve',
                    capacity_change=-quantity,
                    remaining_after=capacity.remaining_capacity,
                    timestamp=datetime.now()
                )
                return True
            return False
    
    def release_capacity(self, vendor_id: UUID, order_id: UUID, reason: str):
        """Release capacity back to hourly slot (on cancellation)"""
        with transaction():
            vendor_order = VendorOrder.objects.get(order_id=order_id)
            capacity = VendorCapacityHourly.objects.select_for_update().get(
                vendor_id=vendor_id,
                date=vendor_order.assigned_date,
                hour=vendor_order.assigned_hour
            )
            
            capacity.remaining_capacity += 1
            capacity.last_updated = datetime.now()
            capacity.save()
            
            # Log transaction
            VendorCapacityLog.objects.create(
                vendor_id=vendor_id,
                date=vendor_order.assigned_date,
                hour=vendor_order.assigned_hour,
                order_id=order_id,
                action='release',
                capacity_change=+1,
                remaining_after=capacity.remaining_capacity,
                reason=reason,
                timestamp=datetime.now()
            )
    
    def reconcile_hourly_capacity(self, vendor_id: UUID, date: date, hour: int):
        """Reconcile capacity for specific hour at end of hour"""
        expected = VendorCapacityHourly.objects.get(
            vendor_id=vendor_id,
            date=date,
            hour=hour
        )
        
        completed = VendorOrder.objects.filter(
            vendor_id=vendor_id,
            assigned_date=date,
            assigned_hour=hour,
            status__in=['delivered', 'completed']
        ).count()
        
        cancelled = VendorOrder.objects.filter(
            vendor_id=vendor_id,
            assigned_date=date,
            assigned_hour=hour,
            status='cancelled'
        ).count()
        
        actual_remaining = expected.total_hourly_capacity - completed
        
        if actual_remaining != expected.remaining_capacity:
            logger.warning(f"Hourly capacity mismatch for vendor {vendor_id} "
                         f"on {date} at {hour}:00 - "
                         f"Expected: {expected.remaining_capacity}, "
                         f"Actual: {actual_remaining}")
    
    def initialize_daily_slots(self, vendor_id: UUID, date: date, hourly_config: dict):
        """Initialize hourly capacity slots for a day"""
        # hourly_config format: {11: 8, 12: 10, 13: 8, 18: 12, 19: 15, 20: 10}
        for hour, capacity in hourly_config.items():
            VendorCapacityHourly.objects.update_or_create(
                vendor_id=vendor_id,
                date=date,
                hour=hour,
                defaults={
                    'total_hourly_capacity': capacity,
                    'remaining_capacity': capacity,
                    'is_active': True,
                    'last_updated': datetime.now()
                }
            )
```

---

### 3.9 Crowdfunding Service

**Responsibilities:**
- Campaign creation and management
- Multi-donor contribution tracking
- Threshold monitoring and order trigger
- Contributor notifications

**Technology Stack:**
- Framework: Node.js (NestJS)
- Database: PostgreSQL
- Message Queue: RabbitMQ (for real-time updates)
- Cache: Redis (for campaign status)

**Campaign Lifecycle:**
```
CREATED → ACTIVE → FUNDING → THRESHOLD_MET → 
ORDER_PLACED → DELIVERED → COMPLETED

Failed states:
→ EXPIRED (time limit reached)
→ CANCELLED (by creator)
```

**Real-time Updates:**
```javascript
// WebSocket for live campaign updates
socket.on('campaign:contribution', (data) => {
  // Update campaign progress bar
  // Notify all watchers
  // Trigger order if threshold met
});
```

**API Endpoints:**
```
POST   /api/v1/campaigns                  # Create campaign
GET    /api/v1/campaigns                  # List campaigns (nearby/all)
GET    /api/v1/campaigns/:id              # Get campaign details
POST   /api/v1/campaigns/:id/contribute   # Contribute to campaign
DELETE /api/v1/campaigns/:id              # Cancel campaign
GET    /api/v1/campaigns/:id/contributors # List contributors
GET    /api/v1/campaigns/my-contributions # User's contributions
POST   /api/v1/campaigns/:id/boost        # Share/boost campaign
```

**Contribution Rules:**
```
- Minimum contribution: ₹10
- Maximum campaign duration: 2 hours
- Auto-cancel if not met: Yes
- Refund on failure: Instant to pledge pool or original source
- Anonymous contributions: Allowed
```

**Data Model:**
```sql
campaigns
├── id (UUID, PK)
├── creator_id (UUID, FK → users.id)
├── seeker_photo_url (VARCHAR)
├── location (GEOGRAPHY)
├── location_address (TEXT)
├── target_amount (DECIMAL)
├── current_amount (DECIMAL)
├── description (TEXT)
├── status (ENUM)
├── created_at (TIMESTAMP)
├── expires_at (TIMESTAMP)
├── order_id (UUID, FK → orders.id, NULLABLE)
├── completed_at (TIMESTAMP, NULLABLE)
└── metadata (JSONB)

campaign_contributions
├── id (UUID, PK)
├── campaign_id (UUID, FK → campaigns.id)
├── contributor_id (UUID, FK → users.id)
├── amount (DECIMAL)
├── is_anonymous (BOOLEAN)
├── payment_reference (VARCHAR)
├── status (ENUM: pending, confirmed, refunded)
├── contributed_at (TIMESTAMP)
└── refunded_at (TIMESTAMP, NULLABLE)

CREATE INDEX idx_campaigns_location ON campaigns USING GIST(location);
CREATE INDEX idx_campaigns_status ON campaigns(status);
CREATE INDEX idx_campaigns_expires ON campaigns(expires_at);
```

**Notification Flow:**
```
1. Campaign created → Notify nearby users
2. Contribution made → Notify creator & all contributors with progress
3. Threshold met → Notify all contributors, trigger order
4. Order delivered → Notify all contributors with delivery photo
5. Campaign expired → Notify all, process refunds
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
    donation_type VARCHAR(30) NOT NULL CHECK (donation_type IN ('food', 'cloth', 'shelter', 'blanket', 'mosquito_net', 'washroom_access', 'miscellaneous')),
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

seeker_detection
├── id (UUID, PK)
├── order_id (UUID, FK → orders.id)
├── seeker_photo_url (VARCHAR)
├── face_embedding (VECTOR(128)) -- Facial recognition vector
├── location (GEOGRAPHY(POINT, 4326))
├── timestamp (TIMESTAMP)
├── is_duplicate (BOOLEAN)
├── matched_order_id (UUID, FK → orders.id, NULLABLE)
├── similarity_score (DECIMAL(3,2))
└── metadata (JSONB)

CREATE INDEX idx_seeker_location ON seeker_detection USING GIST(location);
CREATE INDEX idx_seeker_timestamp ON seeker_detection(timestamp);
CREATE INDEX idx_seeker_face ON seeker_detection USING ivfflat(face_embedding) WITH (lists = 100); -- For vector similarity search (requires pgvector extension)

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

### 4.2 Global Database Architecture (For Production Scale)

**Multi-Region Strategy:**

```yaml
Production Architecture:
  Primary Region: US-East
    - PostgreSQL Primary (Write)
    - Read Replicas (2x for HA)
  
  Secondary Regions:
    - EU-West: Read Replica (for European users)
    - Asia-South: Read Replica (for Asian users)
  
  Routing Logic:
    - Writes: Always to primary (US-East)
    - Reads: Route to nearest replica based on user location
    - Replication Lag: 1-5 seconds (acceptable for most queries)
  
  Benefits:
    - Read latency: 20-50ms (vs 300-500ms single region)
    - Write latency: 100-200ms globally (acceptable)
    - High availability with cross-region failover
  
  Implementation:
    - AWS RDS Multi-AZ + Cross-Region Read Replicas
    - Or Aurora Global Database for multi-master writes
```

**Database Optimization for High Volume:**

```sql
-- Specialized Geospatial Indexes
CREATE INDEX idx_orders_location_gist 
ON orders USING GIST(location) 
WITH (buffering = on, fillfactor = 90);

-- Partial index for active orders (reduces index size)
CREATE INDEX idx_active_orders_location 
ON orders USING GIST(location)
WHERE status IN ('created', 'in_transit', 'confirmed');

-- BRIN index for time-series queries
CREATE INDEX idx_orders_location_brin 
ON orders USING BRIN(location, created_at);

-- Table partitioning by region (for extreme scale)
CREATE TABLE orders_north_america PARTITION OF orders
FOR VALUES IN ('NA');

CREATE TABLE orders_europe PARTITION OF orders
FOR VALUES IN ('EU');

CREATE TABLE orders_asia PARTITION OF orders
FOR VALUES IN ('ASIA');
```

**Connection Pooling (PgBouncer - Required for 10K+ users):**

```ini
[pgbouncer]
pool_mode = transaction
default_pool_size = 25
max_client_conn = 10000
max_db_connections = 100
server_idle_timeout = 600
query_timeout = 30
```

**PostgreSQL Configuration (32GB RAM server):**

```sql
shared_buffers = 8GB                    -- 25% of RAM
effective_cache_size = 24GB             -- 75% of RAM
maintenance_work_mem = 2GB
work_mem = 64MB
max_connections = 200                   -- PgBouncer handles pooling
random_page_cost = 1.1                  -- For SSD storage
max_parallel_workers_per_gather = 4
autovacuum_max_workers = 4
autovacuum_naptime = 30s
```

---

### 4.3 Caching Strategy (Redis)

**Multi-Region Redis Clusters:**

```yaml
Regional Clusters:
  US-East:
    - Primary cache for North American users
    - 3-node cluster for high availability
  
  EU-West:
    - Primary cache for European users
    - 3-node cluster
  
  Asia-South:
    - Primary cache for Asian users
    - 3-node cluster
  
  Replication:
    - Async cross-region replication for hot keys
    - Regional routing based on user location
```

**Cache Keys:**
```
user:session:{userId}           TTL: 24 hours
user:profile:{userId}           TTL: 1 hour
order:active:{orderId}          TTL: 2 hours
vendor:token:{vendor}           TTL: per vendor policy
safety:assessment:{lat}:{lng}   TTL: 30 minutes
rate:limit:{userId}:{endpoint}  TTL: 1 minute
seekers:active                  TTL: 2 hours (geospatial index)
```

**Cache Patterns:**
- **Cache-Aside**: User profiles, order details
- **Write-Through**: Active orders
- **Write-Behind**: Analytics data
- **Geospatial Caching**: Redis GEORADIUS for nearby seekers

**Geospatial Caching with Redis:**

```javascript
// Add seeker to geospatial index
await redis.geoadd('seekers:active', longitude, latitude, seekerId);

// Find nearby seekers (in-memory, ultra-fast)
const nearby = await redis.georadius('seekers:active', 
  userLng, userLat, 1, 'km', 'WITHDIST', 'COUNT', 10);

// Fallback to PostgreSQL for complex queries
if (nearby.length === 0) {
  nearby = await db.orders.findNearby(userLat, userLng, 1000);
}
```

---

### 4.4 Message Queue Architecture

**Recommended: AWS SQS/SNS for Global Scale**

```yaml
Migration from RabbitMQ to Managed Service:
  Reasons:
    - RabbitMQ: Single region, complex clustering
    - AWS SQS/SNS: Multi-region, fully managed, auto-scaling
  
  Regional Deployment:
    - US-East: SQS queues + SNS topics
    - EU-West: SQS queues + SNS topics
    - Asia-South: SQS queues + SNS topics
  
  Cross-Region Fanout:
    - SNS topic in primary region
    - Subscribe SQS queues in all regions
    - Global event propagation < 1 second
  
  Benefits:
    - Zero ops overhead
    - Unlimited throughput
    - Built-in dead letter queues
    - 99.9% SLA
    - Cost: $0.40 per million requests
```

**Queue Topics:**
```
ShareBridge.orders.created
ShareBridge.orders.updated
ShareBridge.orders.completed
ShareBridge.safety.assessed
ShareBridge.photos.uploaded
ShareBridge.notifications.send
ShareBridge.vendor.webhook
ShareBridge.analytics.event
```

**Queue Configuration:**
```yaml
order.created:
  visibility_timeout: 30 seconds
  message_retention: 14 days
  dead_letter_queue: order.created.dlq
  max_receive_count: 3

notification.send:
  visibility_timeout: 60 seconds
  message_retention: 4 days
  batch_size: 10 messages
```

**Consumer Services:**
- Notification Service → `ShareBridge.notifications.send`
- Analytics Service → `ShareBridge.analytics.event`
- Order Service → `ShareBridge.vendor.webhook`

---

## 5. API Design

### 5.1 RESTful API Standards

**Base URL:**
```
https://api.ShareBridge.com/v1
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

**⚠️ Critical Integration Challenge:**

Most major food delivery platforms (Swiggy, Zomato, Uber Eats) **do not provide public APIs** for third-party order placement. This requires:
- Business partnerships and API access negotiations
- Custom adapter implementations for each vendor
- Alternative approaches for MVP phase

**Integration Strategies:**

**Strategy 1: Direct API Integration (Requires Partnership)**
```
Prerequisites:
- Formal business partnership with vendor
- OAuth 2.0 or API key access
- Webhook endpoint registration
- Compliance with vendor terms of service

Challenges:
- Different API structures per vendor
- Different authentication mechanisms
- Different webhook signature formats
- Rate limiting and throttling policies
- Vendor-specific business rules
```

**Strategy 2: Deep Link Integration (Fallback)**
```
Flow:
1. ShareBridge creates order intent (local database)
2. Generate vendor-specific deep link with pre-filled cart
3. Redirect user to vendor app/website
4. User completes order on vendor platform
5. Vendor sends callback/webhook on order status
6. ShareBridge updates local order status

Limitations:
- Less control over order flow
- Dependency on vendor callback reliability
- User leaves ShareBridge app temporarily
- Payment tracking complexity
```

**Strategy 3: Direct Vendor Program with Automated Integration (MVP Approach)**
```
Benefits:
- Full control over integration
- No dependency on third-party APIs
- Immediate implementation possible
- Better margins for social mission
- Fully automated end-to-end workflow

Implementation:
- Partner with local restaurants, home kitchens, and food vendors
- Vendors onboard via ShareBridge Vendor Portal (web/mobile)
- Automated order notification to vendors (push, SMS, in-app)
- Vendor capacity pledge system (hourly slots)
- Vendors mark orders as READY via app
- Automatic logistics partner integration (Dunzo/Porter/Shadowfax)
- Real-time order tracking and status updates
- NO manual steps - fully digital workflow

Key Difference from External Vendors:
- ShareBridge handles payment (Razorpay/Stripe) instead of redirecting
- ShareBridge coordinates delivery logistics
- Vendors only prepare food; rest is automated by platform
```

**Vendor Adapter Pattern (For Future API Access):**

```typescript
interface VendorConfig {
  name: string;
  apiBaseUrl: string;
  authMethod: 'oauth' | 'api_key' | 'partnership';
  webhookSecret: string;
  deepLinkSchema: string;
  requiresCustomAuth: boolean;
  rateLimits: {
    requestsPerMinute: number;
    requestsPerDay: number;
  };
}

interface VendorAdapter {
  createOrder(orderData: OrderData): Promise<VendorOrder>;
  getOrderStatus(vendorOrderId: string): Promise<OrderStatus>;
  generatePaymentLink(vendorOrderId: string): Promise<string>;
  cancelOrder(vendorOrderId: string): Promise<boolean>;
  verifyWebhook(payload: any, signature: string): boolean;
  normalizeResponse(vendorResponse: any): StandardResponse;
}

class VendorService {
  private adapters: Map<string, VendorAdapter>;
  
  async createOrder(vendor: string, orderData: OrderData) {
    const adapter = this.adapters.get(vendor);
    if (!adapter) {
      throw new Error(`Vendor ${vendor} not supported`);
    }
    
    try {
      return await adapter.createOrder(orderData);
    } catch (error) {
      // Fallback to alternative vendor or direct vendor program
      return await this.fallbackOrderCreation(orderData);
    }
  }
  
  async getStatus(vendor: string, vendorOrderId: string) {
    const adapter = this.adapters.get(vendor);
    return await adapter.getOrderStatus(vendorOrderId);
  }
  
  private async fallbackOrderCreation(orderData: OrderData) {
    // Route to direct vendor network
    return await this.directVendorService.createOrder(orderData);
  }
}

// Custom adapter per vendor
class SwiggyAdapter implements VendorAdapter {
  async createOrder(orderData: OrderData) {
    // Swiggy-specific API call structure
    // Requires partnership agreement
  }
  
  verifyWebhook(payload: any, signature: string): boolean {
    // Swiggy-specific signature verification
    const hash = crypto.createHmac('sha256', this.config.webhookSecret)
      .update(JSON.stringify(payload))
      .digest('hex');
    return hash === signature;
  }
}

class ZomatoAdapter implements VendorAdapter {
  async createOrder(orderData: OrderData) {
    // Zomato-specific API call structure
    // Different request format than Swiggy
  }
  
  verifyWebhook(payload: any, signature: string): boolean {
    // Zomato uses different webhook signature method
    // Requires custom verification logic
  }
}
```

**Webhook Handling (Multi-Vendor):**
```typescript
@Post('/vendors/webhooks/:vendor')
async handleWebhook(
  @Param('vendor') vendor: string,
  @Body() payload: any,
  @Headers('signature') signature: string,
  @Headers('x-vendor-event') eventType: string
) {
  // 1. Get vendor-specific adapter
  const adapter = this.vendorService.getAdapter(vendor);
  
  // 2. Verify webhook signature (vendor-specific)
  if (!adapter.verifyWebhook(payload, signature)) {
    this.logger.warn(`Invalid webhook signature from ${vendor}`);
    throw new UnauthorizedException('Invalid signature');
  }
  
  // 3. Normalize vendor-specific data to standard format
  const orderUpdate = adapter.normalizeResponse(payload);
  
  // 4. Update order status
  await this.orderService.updateStatus(
    orderUpdate.ShareBridgeOrderId,
    orderUpdate.status,
    {
      vendorOrderId: orderUpdate.vendorOrderId,
      vendorStatus: orderUpdate.vendorStatus,
      deliveryETA: orderUpdate.estimatedDelivery,
      trackingUrl: orderUpdate.trackingUrl
    }
  );
  
  // 5. Send notification to donor
  await this.notificationService.send({
    userId: orderUpdate.donorId,
    type: 'order_update',
    template: this.getTemplateForStatus(orderUpdate.status),
    data: orderUpdate
  });
  
  return { received: true };
}
```

**Recommended Implementation Phases:**

```
Phase 1 - MVP (Month 1-3):
├── Direct Vendor Program (local restaurants, home kitchens)
├── Automated vendor onboarding via portal
├── Digital order notifications (push/SMS/in-app)
├── Integrated payment gateway (Razorpay/Stripe)
├── Automated logistics integration (Dunzo/Porter)
├── Real-time status tracking
└── No manual steps - fully automated workflow

Phase 2 - Partnership (Month 4-6):
├── Initiate partnerships with Swiggy/Zomato/Uber Eats
├── API access negotiation
├── Pilot program with one major vendor
├── Build custom adapter
└── Hybrid model (direct vendors + platforms)

Phase 3 - Scale (Month 7-12):
├── Multi-vendor support across all channels
├── Full webhook integration for all platforms
├── Intelligent vendor selection (cost, capacity, location)
├── Fallback mechanisms
└── Optimized hybrid approach
```

**API Customization Requirements:**

| Vendor | Customization Level | Key Challenges |
|--------|-------------------|----------------|
| **Swiggy** | High | No public API, requires partnership, custom auth flow |
| **Zomato** | High | Limited API access, different webhook format |
| **Uber Eats** | High | Enterprise partnership needed, complex auth |
| **Direct Vendors** | Medium | Custom integration per vendor, capacity management |
| **Google Maps** | Low | Standard API, well-documented |
| **Twilio/SendGrid** | Low | Standard SDKs available |
| **FCM/APNS** | Low | Standard push notification setup |

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

**Service Integration Matrix:**

| Service | Purpose | Provider Options | Customization Level | Implementation Complexity |
|---------|---------|-----------------|-------------------|-------------------------|
| **SMS** | OTP delivery, alerts | Twilio, AWS SNS, Gupshup | Low | Simple - Standard REST APIs, good SDKs |
| **Push Notifications** | Real-time updates | Firebase FCM, APNS | Low | Standard - Setup required, well-documented |
| **Email** | Receipts, updates | SendGrid, AWS SES | Low | Simple - Template-based, standard APIs |
| **Storage** | Photo storage | AWS S3, Azure Blob, GCP Storage | Low | Standard - SDK available, minimal config |
| **Maps** | Location services | Google Maps, Mapbox | Low | Standard - REST API, extensive docs |
| **Analytics** | Usage tracking | Google Analytics, Mixpanel | Low | Standard - SDK integration |
| **Monitoring** | APM, error tracking | DataDog, New Relic, Sentry | Medium | Moderate - Custom dashboards needed |

**Detailed Integration Specifications:**

#### **SMS Service (Twilio - Recommended)**
```javascript
// Minimal customization - Standard SDK
const twilio = require('twilio');
const client = twilio(accountSid, authToken);

async function sendOTP(phoneNumber, otp) {
  await client.messages.create({
    body: `Your ShareBridge OTP is: ${otp}. Valid for 5 minutes.`,
    from: process.env.TWILIO_PHONE,
    to: phoneNumber
  });
}

// Integration effort: 1-2 days
// Cost: ~$0.0075 per SMS in India
```

#### **Push Notifications (Firebase FCM)**
```javascript
// Low customization - Standard setup
const admin = require('firebase-admin');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

async function sendPushNotification(deviceToken, notification) {
  await admin.messaging().send({
    token: deviceToken,
    notification: {
      title: notification.title,
      body: notification.body
    },
    data: notification.data,
    android: {
      priority: 'high'
    },
    apns: {
      headers: {
        'apns-priority': '10'
      }
    }
  });
}

// Integration effort: 2-3 days (including mobile SDK setup)
// Cost: Free
```

#### **Email Service (SendGrid)**
```javascript
// Low customization - Template-based
const sgMail = require('@sendgrid/mail');
sgMail.setApiKey(process.env.SENDGRID_API_KEY);

async function sendReceipt(email, orderData) {
  await sgMail.send({
    to: email,
    from: 'noreply@ShareBridge.org',
    templateId: 'd-xxxxx', // Dynamic template
    dynamicTemplateData: {
      orderId: orderData.id,
      amount: orderData.amount,
      items: orderData.items
    }
  });
}

// Integration effort: 1-2 days
// Cost: Free tier (100 emails/day), then ~$0.0006/email
```

#### **Cloud Storage (AWS S3)**
```javascript
// Low customization - Standard SDK
const AWS = require('aws-sdk');
const s3 = new AWS.S3();

async function uploadPhoto(file, orderId) {
  const params = {
    Bucket: 'ShareBridge-photos',
    Key: `orders/${orderId}/${Date.now()}-${file.name}`,
    Body: file.buffer,
    ContentType: file.mimetype,
    ServerSideEncryption: 'AES256',
    Metadata: {
      'order-id': orderId,
      'upload-timestamp': new Date().toISOString()
    }
  };
  
  const result = await s3.upload(params).promise();
  return result.Location;
}

// Integration effort: 1 day
// Cost: ~$0.023 per GB/month storage
```

#### **Google Maps API**
```javascript
// Low customization - Well-documented REST API
const { Client } = require('@googlemaps/google-maps-services-js');
const client = new Client({});

async function assessLocation(lat, lng) {
  // Geocoding
  const geocode = await client.reverseGeocode({
    params: {
      latlng: { lat, lng },
      key: process.env.GOOGLE_MAPS_API_KEY
    }
  });
  
  // Nearby places
  const places = await client.placesNearby({
    params: {
      location: { lat, lng },
      radius: 100,
      key: process.env.GOOGLE_MAPS_API_KEY
    }
  });
  
  // Traffic data (requires Roads API)
  const roads = await client.nearestRoads({
    params: {
      points: `${lat},${lng}`,
      key: process.env.GOOGLE_MAPS_API_KEY
    }
  });
  
  return {
    address: geocode.data.results[0].formatted_address,
    placeTypes: places.data.results.map(p => p.types),
    nearestRoad: roads.data.snappedPoints[0]
  };
}

// Integration effort: 2-3 days
// Cost: $5 per 1000 requests (Geocoding), $10 per 1000 (Places)
```

**Integration Timeline Summary:**

```
Week 1-2: Core Services
├── Firebase FCM setup (Push notifications)
├── Twilio integration (SMS)
├── AWS S3 bucket setup (Photo storage)
└── SendGrid templates (Email)

Week 3: Enhanced Services
├── Google Maps API integration
├── Analytics setup (Google Analytics/Mixpanel)
└── Basic monitoring (Sentry for errors)

Week 4: Production Readiness
├── DataDog APM setup
├── Load testing integrations
└── Webhook reliability testing
```

**No Significant Customization Required For:**
- SMS/Email/Push - Standard APIs with excellent SDKs
- Cloud Storage - Plug-and-play with minimal configuration
- Google Maps - Well-documented REST API
- Analytics - JavaScript tag integration

**Moderate Customization Required For:**
- Monitoring/APM - Custom dashboards for ShareBridge-specific metrics
- Error Tracking - Custom error contexts and user data attachments

---

## 8. AI/ML Pipeline

### 8.1 Safety Assessment Model

**Approach: Rule-Based Scoring with Existing APIs (No Custom ML Training Required)**

**Architecture:**
```
Input: Location coordinates (lat, lng) + Timestamp
Data Sources: External APIs (no training needed)
Processing: Rule-based weighted scoring
Output: Safety score (0.0 - 1.0)
Threshold: >= 0.65 for approval
```

**Data Sources & APIs:**
```python
# 1. Google Maps Traffic API - Real-time traffic data
# 2. Google Places API - Location type (residential, commercial, etc.)
# 3. Google Maps Roads API - Road classification
# 4. OpenWeather API - Weather conditions
# 5. SunCalc Library - Daylight calculation
# 6. Internal Database - Historical delivery success rate
# 7. Optional: Public crime data APIs (government open data)
```

**Implementation (Rule-Based Scoring):**
```python
from datetime import datetime
import requests
from suncalc import get_times
import math

class SafetyAssessmentService:
    def __init__(self):
        self.google_maps_key = os.getenv('GOOGLE_MAPS_API_KEY')
        self.openweather_key = os.getenv('OPENWEATHER_API_KEY')
        
    async def assess_safety(self, lat: float, lng: float, timestamp: datetime) -> dict:
        """
        Calculate safety score using external APIs and rule-based logic.
        No ML training required - uses real-time data from trusted sources.
        """
        # Parallel API calls for efficiency
        traffic_score = await self.get_traffic_safety_score(lat, lng)
        time_score = self.calculate_time_safety_score(lat, lng, timestamp)
        location_score = await self.get_location_type_score(lat, lng)
        historical_score = await self.get_historical_success_rate(lat, lng)
        
        # Weighted scoring
        safety_score = (
            traffic_score * 0.25 +      # Traffic conditions
            time_score * 0.20 +          # Daylight/time of day
            location_score * 0.30 +      # Location type (public/residential)
            historical_score * 0.25      # Past delivery success
        )
        
        return {
            'safety_score': safety_score,
            'is_safe': safety_score >= 0.65,
            'breakdown': {
                'traffic': traffic_score,
                'time_of_day': time_score,
                'location_type': location_score,
                'historical': historical_score
            },
            'recommendations': self.generate_recommendations(safety_score, {
                'traffic': traffic_score,
                'time': time_score,
                'location': location_score
            })
        }
    
    async def get_traffic_safety_score(self, lat: float, lng: float) -> float:
        """Get traffic safety score from Google Maps Traffic API"""
        url = f"https://maps.googleapis.com/maps/api/directions/json"
        params = {
            'origin': f'{lat},{lng}',
            'destination': f'{lat},{lng}',  # Same point for current traffic
            'departure_time': 'now',
            'key': self.google_maps_key
        }
        
        response = requests.get(url, params=params)
        data = response.json()
        
        # Extract traffic conditions
        if 'routes' in data and len(data['routes']) > 0:
            duration = data['routes'][0]['legs'][0].get('duration', {})
            duration_in_traffic = data['routes'][0]['legs'][0].get('duration_in_traffic', {})
            
            # Compare normal vs traffic duration
            if duration and duration_in_traffic:
                traffic_ratio = duration['value'] / duration_in_traffic['value']
                # Higher ratio = worse traffic = lower score
                return min(traffic_ratio, 1.0)
        
        # Use Roads API for road type
        roads_url = f"https://roads.googleapis.com/v1/nearestRoads"
        roads_params = {
            'points': f'{lat},{lng}',
            'key': self.google_maps_key
        }
        roads_response = requests.get(roads_url, params=roads_params)
        roads_data = roads_response.json()
        
        # Main roads = higher score
        if 'snappedPoints' in roads_data:
            return 0.8  # Good traffic accessibility
        
        return 0.6  # Default moderate score
    
    def calculate_time_safety_score(self, lat: float, lng: float, timestamp: datetime) -> float:
        """Calculate safety based on time of day using daylight hours"""
        # Get sunrise/sunset times for location
        times = get_times(timestamp.date(), lng, lat)
        sunrise = times['sunrise']
        sunset = times['sunset']
        
        # Check if within daylight hours
        if sunrise <= timestamp <= sunset:
            # Daylight hours - full score
            return 1.0
        else:
            # Night time - calculate how far into night
            hours_after_sunset = (timestamp - sunset).total_seconds() / 3600
            hours_before_sunrise = (sunrise - timestamp).total_seconds() / 3600
            
            # Early evening (0-2 hours after sunset) or early morning (0-2 hours before sunrise)
            if hours_after_sunset <= 2 or hours_before_sunrise <= 2:
                return 0.7
            # Late night
            else:
                return 0.4
    
    async def get_location_type_score(self, lat: float, lng: float) -> float:
        """Get location type score from Google Places API"""
        url = f"https://maps.googleapis.com/maps/api/place/nearbysearch/json"
        params = {
            'location': f'{lat},{lng}',
            'radius': 200,  # 200 meter radius
            'key': self.google_maps_key
        }
        
        response = requests.get(url, params=params)
        data = response.json()
        
        if 'results' not in data or len(data['results']) == 0:
            return 0.5  # Isolated area - moderate score
        
        # Analyze nearby places
        place_types = []
        for place in data['results'][:10]:  # Check top 10 nearby places
            place_types.extend(place.get('types', []))
        
        # Score based on place types
        public_places = ['hospital', 'police', 'school', 'park', 'shopping_mall', 
                        'restaurant', 'cafe', 'store', 'transit_station']
        residential = ['neighborhood', 'street_address', 'premise']
        
        public_count = sum(1 for pt in place_types if pt in public_places)
        residential_count = sum(1 for pt in place_types if pt in residential)
        
        if public_count > 3:
            return 0.9  # Busy public area - very safe
        elif residential_count > 2:
            return 0.8  # Residential area - safe
        else:
            return 0.6  # Mixed/unclear - moderate
    
    async def get_historical_success_rate(self, lat: float, lng: float) -> float:
        """Get historical delivery success rate from internal database"""
        # Query orders within 500m radius
        query = """
            SELECT 
                COUNT(*) as total,
                SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as successful
            FROM orders
            WHERE ST_DWithin(
                location::geography,
                ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography,
                500
            )
            AND created_at > NOW() - INTERVAL '90 days'
        """
        
        result = await db.fetch_one(query, lng, lat)
        
        if result['total'] == 0:
            return 0.7  # No history - assume moderate safety
        
        success_rate = result['successful'] / result['total']
        return success_rate
    
    def generate_recommendations(self, score: float, breakdown: dict) -> list:
        """Generate recommendations based on score breakdown"""
        recommendations = []
        
        if breakdown['traffic'] < 0.5:
            recommendations.append("High traffic area - delivery may take longer")
        
        if breakdown['time'] < 0.6:
            recommendations.append("Night time delivery - extra caution advised")
        
        if breakdown['location'] < 0.6:
            recommendations.append("Isolated location - ensure good communication")
        
        if score >= 0.65:
            recommendations.append("Location approved for delivery")
        else:
            recommendations.append("Consider alternative location or time")
        
        return recommendations
```

**Benefits of Rule-Based Approach:**
- ✅ No ML training required - works immediately
- ✅ Uses authoritative data sources (Google, OpenWeather)
- ✅ Real-time data instead of trained predictions
- ✅ Easy to understand and debug
- ✅ No model drift or retraining overhead
- ✅ Lower infrastructure costs (no ML pipeline)
- ✅ Transparent scoring logic
- ✅ Can be updated with simple configuration changes

**Cost Considerations:**

**Previous Approach (Custom ML):**
- ML Infrastructure (GPU instances): ~$500-1000/month
- MLflow/model registry: ~$50-100/month
- Training data storage: ~$50/month
- Model retraining compute: ~$100-200/month
- Data scientists/ML engineers: Ongoing operational cost
- **Total ML Infrastructure: ~$700-1350/month**

**New Approach (API-Based Rule System):**
- Google Maps API:
  - Directions API (traffic): $5 per 1000 requests
  - Roads API: $10 per 1000 requests  
  - Places API: $17 per 1000 requests
  - Combined: ~$32 per 1000 safety assessments
  - At 1000 assessments/day: ~$960/month
  - At 100 assessments/day (realistic MVP): ~$96/month
- OpenWeather API: Free tier (60 calls/min) or $40/month for paid
- SunCalc library: Free (npm package)
- Rule-based compute: Negligible (~$5/month serverless)
- **Total API-Based: ~$100-1000/month (volume dependent)**

**Cost Comparison at Different Scales:**

| Daily Assessments | ML Approach | API Approach | Savings |
|------------------|-------------|--------------|---------|
| 100 (MVP)        | $700-1350   | $100-150     | ~$600-1200 (85% cheaper) |
| 1,000 (Growth)   | $700-1350   | $960-1000    | Break-even to slight savings |
| 5,000+ (Scale)   | $700-1350   | $4,800+      | ML becomes cheaper |

**Key Insights:**
- ✅ **MVP/Early Stage**: API approach is 85% cheaper
- ✅ **No upfront investment**: No ML infrastructure needed
- ✅ **Pay-as-you-grow**: Costs scale with actual usage
- ⚠️ **At scale (5000+/day)**: Custom ML becomes cost-effective
- 💡 **Strategy**: Start with APIs, migrate to ML when volume justifies it

**Optimization Strategies:**
1. Cache safety scores for frequently requested locations (reduce API calls by 40-60%)
2. Batch nearby assessments
3. Use Google Maps API quota optimization
4. Implement tiered assessment (quick check first, detailed only if needed)

**Example with Caching:**
- 1000 assessments/day, 50% cache hit rate
- Actual API calls: 500/day
- Cost: ~$480/month instead of $960/month

**Recommendation for MVP:**
Start with API-based approach. It's cheaper, faster to implement, and requires no ML expertise. Switch to custom ML only when reaching 3000-5000 assessments/day.

---

**Phased Implementation Strategy:**

**Phase 1: MVP (Months 1-3, 0-500 orders/day)**
```yaml
Safety Assessment:
  Approach: API-based rule system
  Infrastructure: Google Cloud free credits ($300)
  Cost: $0/month (within free tier)
  Features:
    - Google Maps APIs (traffic, places, roads)
    - OpenWeather free tier
    - SunCalc library (free)
    - Rule-based weighted scoring
    - Basic location caching (1 hour)
  
Vendor Integration:
  Approach: Direct Vendor Program only
  Features:
    - Local restaurants/home kitchens
    - Automated vendor portal
    - Hourly capacity management
    - Push/SMS notifications to vendors
    - Integrated payment (Razorpay/Stripe)
    - Logistics automation (Dunzo/Porter)
  Cost: $0 infrastructure (pay only for actual deliveries)
  Benefits:
    - Full control over workflow
    - No dependency on platform APIs
    - Faster onboarding
    - Better margins for charity
```

**Phase 2: Growth (Months 4-6, 500-2000 orders/day)**
```yaml
Safety Assessment:
  Approach: Optimized API-based system
  Infrastructure: Production API quotas
  Cost: $300-500/month
  Enhancements:
    - Advanced caching (50% hit rate)
    - Batch processing for nearby locations
    - Historical data analytics
    - API quota optimization
    - Fallback to simplified scoring if API limits reached

Vendor Integration:
  Approach: Hybrid (Direct + Platform partnerships)
  Features:
    - Continue direct vendor network (primary)
    - Begin Swiggy/Zomato partnership discussions
    - Deep link integration (fallback option)
    - Vendor selection algorithm (cost, capacity, location)
    - Multi-vendor order routing
  Cost: $0 additional infrastructure
  Benefits:
    - Redundancy and reliability
    - Wider coverage area
    - Better donor experience
```

**Phase 3: Scale (Months 7-12, 2000-5000+ orders/day)**
```yaml
Safety Assessment:
  Decision Point: Evaluate ML vs API costs
  
  Option A: Continue API-based (if cost-effective)
    Cost: $800-1200/month
    Enhancements:
      - Multi-level caching (location + time)
      - Pre-computed safety zones
      - Tiered assessment (quick check first)
  
  Option B: Migrate to Custom ML (if volume justifies)
    Cost: $700-1000/month (fixed)
    Implementation:
      - 3-month training data collection
      - Custom ML model (Random Forest/Gradient Boosting)
      - MLflow deployment
      - A/B testing against API baseline
      - Gradual rollout (10% → 50% → 100%)
    Benefits:
      - Fixed costs at scale
      - Customized to Indian delivery patterns
      - No API rate limits

Vendor Integration:
  Approach: Full multi-vendor ecosystem
  Features:
    - Direct vendors (60-70% of orders)
    - Swiggy API integration (if partnership secured)
    - Zomato API integration (if partnership secured)
    - UberEats (future)
    - Intelligent routing algorithm
      * Cost optimization
      * Capacity availability
      * Delivery time prediction
      * Historical vendor performance
    - Automated failover between vendors
  Cost: Development + API costs (variable)
  Benefits:
    - Maximum coverage
    - Best pricing through competition
    - High reliability
```

**Decision Framework:**

| Metric | MVP (Phase 1) | Growth (Phase 2) | Scale (Phase 3) |
|--------|---------------|------------------|------------------|
| Daily Orders | 0-500 | 500-2000 | 2000-5000+ |
| Safety Assessments | 0-500/day | 500-2000/day | 2000-5000+/day |
| Safety Cost | $0 (free tier) | $300-500/month | $700-1200/month |
| Approach | API-based | API-based optimized | ML or API (evaluate) |
| Vendor Strategy | Direct only | Hybrid | Full ecosystem |
| Vendor Cost | Per delivery | Per delivery | Per delivery + API |
| Infrastructure | Free tier | Paid tier | Production scale |
| Team Focus | Fast launch | Optimization | Partnerships + ML |

**Migration Triggers:**

Phase 1 → Phase 2:
- ✅ Consistent 300+ orders/day for 2 weeks
- ✅ 10+ active vendors in network
- ✅ API costs approaching $200/month
- ✅ 95%+ delivery success rate

Phase 2 → Phase 3:
- ✅ Consistent 1500+ orders/day for 1 month
- ✅ API costs exceeding $600/month
- ✅ 50+ active vendors
- ✅ Partnership discussions with major platforms progressing
- ⚠️ Evaluate: ML training feasible (3 months of quality data)

**Recommendation:**
Start with Phase 1 approach. Monitor costs and scale metrics monthly. Make Phase 2/3 decisions based on actual data, not projections.

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
    url = upload_to_s3(encrypted, bucket='ShareBridge-photos')
    
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
        image: ShareBridge/order-service:1.0.0
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

### 10.1 Global Deployment Architecture

**Multi-Region Deployment Strategy:**

```
┌─────────────────────────────────────────────────────────────┐
│                  GLOBAL DEPLOYMENT                           │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Route 53 Geolocation Routing                               │
│  ├── US/Canada → api-us-east.sharebridge.com               │
│  ├── Europe → api-eu-west.sharebridge.com                  │
│  ├── Asia → api-asia-south.sharebridge.com                 │
│  └── Default → api-us-east.sharebridge.com                 │
│                                                              │
│  Region: US-East                                            │
│  ├── API Gateway + Load Balancer (3 AZs)                   │
│  ├── Services: Order, User, Integration (2-10 instances)   │
│  ├── PostgreSQL Primary + Read Replicas                    │
│  ├── Redis Cluster (3 nodes)                               │
│  └── S3 Primary Storage                                     │
│                                                              │
│  Region: EU-West                                            │
│  ├── API Gateway + Load Balancer (3 AZs)                   │
│  ├── Services: Order, User, Integration (2-10 instances)   │
│  ├── PostgreSQL Read Replica                               │
│  ├── Redis Cluster (3 nodes)                               │
│  └── S3 Replica Storage                                     │
│                                                              │
│  Region: Asia-South                                         │
│  ├── API Gateway + Load Balancer (3 AZs)                   │
│  ├── Services: Order, User, Integration (2-10 instances)   │
│  ├── PostgreSQL Read Replica                               │
│  ├── Redis Cluster (3 nodes)                               │
│  └── S3 Replica Storage                                     │
│                                                              │
│  CloudFront CDN (200+ edge locations globally)             │
│  ├── Photo delivery from nearest edge                       │
│  ├── Static asset caching                                   │
│  └── Origin failover (primary → replicas)                  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

**Regional Routing Logic:**

```javascript
function determineRegion(userLocation) {
  const { lat, lng } = userLocation;
  
  // North America
  if (lat > 15 && lat < 72 && lng > -170 && lng < -50) {
    return 'us-east';
  }
  // Europe
  else if (lat > 35 && lat < 72 && lng > -10 && lng < 40) {
    return 'eu-west';
  }
  // Asia
  else if (lat > -10 && lat < 55 && lng > 40 && lng < 150) {
    return 'asia-south';
  }
  // Default
  return 'us-east';
}
```

---

### 10.2 Horizontal Scaling Strategy

**Auto-scaling Rules (Per Region):**
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

# Geographic Auto-scaling
Regional traffic spike > 2x baseline → Add instances
Off-peak hours (2AM-6AM local) → Scale to minimum
```

---

### 10.3 Performance Targets

**Global Performance Metrics:**

| Metric | Target (Single Region) | Target (Global) | Measurement |
|--------|----------------------|-----------------|-------------|
| API Response Time (p95) | < 200ms | < 150ms | Load balancer metrics |
| API Response Time (p99) | < 500ms | < 300ms | Load balancer metrics |
| Safety Assessment | < 2s | < 1.5s | Service-level metric |
| Photo Upload | < 5s | < 2s | End-to-end (nearest region) |
| Photo Download | N/A | < 500ms | CloudFront edge delivery |
| Order Creation | < 3s | < 2s | End-to-end |
| Database Query (p95) | < 50ms | < 30ms | PostgreSQL metrics (local replica) |
| Database Write (p95) | < 50ms | < 150ms | PostgreSQL metrics (to primary) |
| Cache Hit Rate | > 80% | > 85% | Redis metrics (regional) |
| Geospatial Query (p95) | < 100ms | < 50ms | With optimized indexes + cache |
| Cross-Region Replication Lag | N/A | < 5s | RDS metrics |
| Uptime (per region) | 99.9% | 99.95% | Monthly average |
| Global Uptime | N/A | 99.99% | With multi-region failover |

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

**Photo Storage (Global Distribution):**

```yaml
Architecture:
  Primary Storage: S3 US-East
  Replication:
    - S3 EU-West (automatic cross-region replication)
    - S3 Asia-South (automatic cross-region replication)
  
  CDN: CloudFront with 200+ Edge Locations
    - Cache TTL: 24 hours
    - Origin Failover: Primary → EU → Asia
    - Compression: Gzip/Brotli enabled
  
  Upload Strategy:
    - Direct upload to nearest S3 region (pre-signed URLs)
    - Client-side compression before upload
    - Async replication to other regions
  
  Performance:
    - Upload: 100-300ms (nearest region)
    - Download: 50-150ms (from CDN edge)
    - Global availability: 99.99%

Backups:
  - S3 versioning enabled
  - Cross-region replication
  - Lifecycle policy: 30 days → delete (GDPR compliance)
```

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
**Owner:** ShareBridge Engineering Team

---

*This technical architecture is designed to be scalable, maintainable, and aligned with modern cloud-native best practices.*
