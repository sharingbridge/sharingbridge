# ShareBridge - Implementation Approach

**Version:** 2.0  
**Date:** January 7, 2026  
**Status:** Dual-Track Implementation Roadmap

---

## Executive Summary

This document provides two implementation paths for ShareBridge:

1. **Free Tier Development Track** - Zero-cost development and testing using free platforms
2. **Production Scale Track** - Global infrastructure for 100K+ orders/day

**Timeline:** 6 months  
**Development Budget:** $0 (Free tier)  
**Production Budget:** $255/month → $3,750/month (scaling)  
**Team Size:** 3-5 engineers

---

## 🆓 Free Tier Development Track

### Overview

Develop and test all ShareBridge components using **100% free platforms** with no upfront infrastructure costs. Migrate to production AWS infrastructure only when all components are ready.

**Total Development Cost:** $0  
**Migration Time:** 1 week  
**Migration Cost:** Minimal (containerized architecture)

---

### Free Development Stack

| Component | Free Platform | Limitations | Production Path |
|-----------|---------------|-------------|-----------------|
| **Database** | Supabase (Postgres + PostGIS) | 500MB, 2GB bandwidth/month | Migrate to AWS RDS/self-hosted |
| **Backend API** | Render.com / Railway.app | 512MB RAM, sleeps after inactivity | Deploy to AWS EC2/ECS |
| **File Storage** | Cloudinary Free Tier | 25GB storage, 25GB bandwidth | Migrate to AWS S3 |
| **Redis Cache** | Upstash Redis | 10K commands/day | Migrate to AWS ElastiCache |
| **Message Queue** | Upstash Kafka Free / Redis Pub/Sub | Limited throughput | Migrate to AWS SQS/SNS |
| **SMS/OTP** | (Optional/Future) | Not enabled for MVP | Enable if needed |
| **Email** | Resend.io / Brevo (Sendinblue) | 100 emails/day | Upgrade to SendGrid |
| **Push Notifications** | Firebase FCM | Unlimited (free forever) | Keep Firebase |
| **Monitoring** | Sentry Free | 5K errors/month | Upgrade or self-host |
| **CI/CD** | GitHub Actions | 2K minutes/month | Keep GitHub Actions |
| **Version Control** | GitHub | Unlimited private repos | Keep GitHub |
| **API Gateway** | Self-hosted Kong (Docker) | Manual setup | Keep or move to AWS |

---

### Quick Start (Day 1) - Free Tier

```bash
# 1. Clone repository
git clone https://github.com/yourusername/sharebridge
cd sharebridge

# 2. Set up Supabase database
# - Sign up at supabase.com (no credit card required)
# - Create project: sharebridge-dev
# - Run schema from ShareBridge_Technical_Architecture.md

# 3. Configure environment variables
cp .env.example .env
# Edit .env with Supabase credentials, Cloudinary keys, etc.

# 4. Run locally with Docker
docker-compose up

# 5. Deploy to Render.com
# - Connect GitHub repo
# - Auto-deploy on push

# Total time: 2-3 hours
# Total cost: $0
```

---

---

## Phase 1: Foundation (Months 1-2) - Free Tier

### **Week 1-2: Database Setup**

**Platform:** Supabase (Free PostgreSQL with PostGIS)

```bash
# Sign up at https://supabase.com (no credit card required)
# Create project: sharebridge-dev

# Enable PostGIS extension via Supabase Dashboard
# SQL Editor → Run:
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pgvector;
```

**Database Schema:**
```sql
-- Run all schema from ShareBridge_Technical_Architecture.md
-- Use Supabase SQL Editor or migrate tool
```

**Connection String:**
```javascript
// Use Supabase connection pooling (built-in)
const dbConfig = {
  host: 'db.your-project.supabase.co',
  port: 5432,
  database: 'postgres',
  user: 'postgres',
  password: 'your-project-password',
  max: 20  // Supabase free tier handles pooling
};
```

**Limitations:**
- 500MB database size (enough for 50K+ test orders)
- 2GB bandwidth/month (500-1K test requests/day)
- No read replicas (single instance only)

**Workaround:** Clean test data regularly, use seed scripts

**Deliverables:**
- [ ] Supabase project created
- [ ] PostGIS extension enabled
- [ ] Database schema deployed
- [ ] Connection pooling configured
- [ ] Sample data seeded

---

### **Week 3-4: Backend API Development**

**Platform:** Render.com or Railway.app (Free tier)

**Setup:**
```bash
# 1. Create Dockerfile for your Node.js/Python backend
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["npm", "start"]

# 2. Push to GitHub
git init
git add .
git commit -m "Initial backend"
git remote add origin https://github.com/yourusername/sharebridge-api
git push -u origin main

# 3. Deploy on Render.com
# - Connect GitHub repo
# - Auto-deploy on push
# - Free tier: 512MB RAM, sleeps after 15min inactivity
```

**Alternative - Railway.app:**
```bash
# Install Railway CLI
npm i -g @railway/cli

# Deploy
railway login
railway init
railway up
```

**Limitations:**
- Server sleeps after inactivity (first request takes 30s to wake)
- 512MB RAM (enough for development)
- No horizontal scaling

**Workaround:** Use free "keep alive" services (cron-job.org) to ping every 10 minutes

**Deliverables:**
- [ ] Backend API deployed to Render/Railway
- [ ] Auto-deploy on GitHub push configured
- [ ] API documentation (Swagger/OpenAPI)
- [ ] Health check endpoint working
- [ ] Environment variables configured

---

### **Week 5-6: File Storage**

**Platform:** Cloudinary (Free tier: 25GB storage, 25GB bandwidth)

```javascript
// Install
npm install cloudinary

// Configure
const cloudinary = require('cloudinary').v2;

cloudinary.config({
  cloud_name: 'your_cloud_name',
  api_key: 'your_api_key',
  api_secret: 'your_api_secret'
});

// Upload seeker photo
const uploadSeekerPhoto = async (file) => {
  const result = await cloudinary.uploader.upload(file, {
    folder: 'sharebridge/seekers',
    transformation: [
      { width: 800, height: 800, crop: 'limit' },
      { quality: 'auto' }
    ]
  });
  
  return result.secure_url;
};
```

**Limitations:**
- 25GB storage (10K+ photos at avg 2MB)
- 25GB bandwidth/month

**Workaround:** Compress images to 500KB max, delete test data regularly

**Deliverables:**
- [ ] Cloudinary account created
- [ ] Photo upload/delete implemented
- [ ] Image optimization configured (< 500KB)
- [ ] CDN URLs working
- [ ] Fallback error handling

---

### **Week 7-8: Caching Layer**

**Platform:** Upstash Redis (Free tier: 10K commands/day)

```bash
# Sign up at https://upstash.com
# Create Redis database (serverless, pay-per-request)
# Get connection URL from dashboard
```

```javascript
// Install
npm install @upstash/redis

// Configure
const { Redis } = require('@upstash/redis');

const redis = new Redis({
  url: 'https://your-endpoint.upstash.io',
  token: 'your-token'
});

// Cache geospatial data (limited usage)
await redis.geoadd('seekers:active', 77.5946, 12.9716, 'seeker123');
const nearby = await redis.georadius('seekers:active', 77.5946, 12.9716, 1, 'km');
```

**Limitations:**
- 10K commands/day (333 requests/hour)
- Shared instance (slower than dedicated)

**Workaround:** 
- Use for critical caching only (beneficiary history, session)
- Fall back to in-memory cache for less critical data

**Deliverables:**
- [ ] Upstash Redis configured
- [ ] Geospatial caching implemented
- [ ] Session management working
- [ ] Cache fallback logic implemented
- [ ] Cache invalidation tested

---

## Phase 2: Core Features (Months 3-4) - Free Tier

### **Week 1-2: Message Queue**

**Platform:** Upstash Kafka (Free tier) or Redis Pub/Sub

```javascript
// Option 1: Upstash Kafka (better for production-like testing)
const { Kafka } = require('@upstash/kafka');

const kafka = new Kafka({
  url: 'https://your-kafka.upstash.io',
  username: 'user',
  password: 'pass'
});

// Publish event
await kafka.producer().produce('order-created', {
  orderId: '123',
  donorId: 'donor456'
});

// Option 2: Redis Pub/Sub (simpler, uses existing Redis quota)
await redis.publish('order-created', JSON.stringify({ orderId: '123' }));
```

**Limitations:**
- Upstash Kafka: Limited messages/day
- Redis: Counts against 10K command quota

**Workaround:** Queue only critical events during dev/test

**Deliverables:**
- [ ] Message queue configured
- [ ] Event schemas documented
- [ ] Producers implemented
- [ ] Consumers implemented
- [ ] Dead letter queue handling

---


### **Week 3-4: Email Only (MVP)**

*SMS is not enabled for MVP. Use push, in-app, or email notifications. Add SMS later if required for non-app users.*

**Email:** Resend.io (Free: 100 emails/day)
```javascript
const { Resend } = require('resend');
const resend = new Resend('re_your_api_key');

await resend.emails.send({
  from: 'sharebridge@yourdomain.com',
  to: 'donor@example.com',
  subject: 'Order Confirmation',
  html: '<p>Your donation was successful!</p>'
});
```

**Deliverables:**
- [ ] Twilio trial configured
- [ ] OTP delivery working
- [ ] Resend.io configured
- [ ] Email templates created
- [ ] Retry logic implemented

---

### **Week 5-6: Push Notifications**

**Platform:** Firebase Cloud Messaging (Free forever)

```bash
# 1. Create Firebase project at console.firebase.google.com
# 2. Download google-services.json (Android) / GoogleService-Info.plist (iOS)
```

```javascript
const admin = require('firebase-admin');
const serviceAccount = require('./firebase-adminsdk.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

// Send push notification
await admin.messaging().send({
  notification: {
    title: 'Order Confirmed',
    body: 'Your food donation is being prepared'
  },
  token: userDeviceToken
});
```

**Deliverables:**
- [ ] Firebase project created
- [ ] Push notifications working on iOS
- [ ] Push notifications working on Android
- [ ] Notification templates created
- [ ] Token management implemented

---

### **Week 7: AI Safety Assessment Service**

**Approach:** Rule-Based API Integration (No ML Training)

**Platform:** Free tier APIs

```javascript
// Safety assessment using external APIs
class SafetyAssessmentService {
  async assessLocation(lat, lng, timestamp) {
    // 1. Google Maps API (use $300 GCP free credit)
    const traffic = await this.getTrafficScore(lat, lng);
    
    // 2. Free daylight calculation (SunCalc library)
    const timeScore = this.calculateDaylightScore(lat, lng, timestamp);
    
    // 3. Google Places API (use $300 GCP free credit)
    const locationScore = await this.getLocationTypeScore(lat, lng);
    
    // 4. Internal database (free)
    const historicalScore = await this.getHistoricalRate(lat, lng);
    
    // 5. Rule-based scoring (no ML needed)
    const safetyScore = (
      traffic * 0.25 +
      timeScore * 0.20 +
      locationScore * 0.30 +
      historicalScore * 0.25
    );
    
    return {
      score: safetyScore,
      is_safe: safetyScore >= 0.65,
      breakdown: { traffic, timeScore, locationScore, historicalScore }
    };
  }
}
```

**Cost During Development:**
- Google Cloud Platform: $300 free credit (12 months)
- Covers ~10,000-15,000 safety assessments
- OpenWeather API: Free tier (60 calls/min)
- SunCalc library: Free
- Total: $0/month

**Migration to Production:**
- Phase 1 (MVP): Continue with API approach (~$100-150/month for 100 assessments/day)
- Phase 2 (Growth): Add caching, optimize API usage (~$500/month for 1000/day)
- Phase 3 (Scale): Consider custom ML model only at 5000+/day

**Deliverables:**
- [ ] Google Maps API configured with free credits
- [ ] Rule-based safety scoring implemented
- [ ] Location caching strategy deployed
- [ ] Safety thresholds configured
- [ ] API cost monitoring enabled

---

### **Week 8: Vendor Integration Strategy**

**Phase-Based Vendor Integration:**

**MVP Phase (Months 1-3):**
```javascript
// Focus: Direct Vendor Program (Full automation, no external APIs)

class DirectVendorService {
  async createOrder(orderData) {
    // 1. Find available vendor with hourly capacity
    const vendor = await this.findAvailableVendor(
      orderData.location,
      orderData.prepTime
    );
    
    // 2. Reserve hourly slot
    await this.reserveCapacity(vendor.id, currentHour);
    
    // 3. Send automated notification to vendor
    await this.notifyVendor(vendor.id, orderData);
    
    // 4. Vendor accepts/prepares via app
    // 5. Auto-trigger logistics partner when READY
    await this.triggerLogistics(vendor.location, orderData.seekerLocation);
    
    return { vendorId: vendor.id, status: 'processing' };
  }
}
```

**Growth Phase (Months 4-6):**
```javascript
// Add: Partnership discussions with Swiggy/Zomato
// Implementation: Deep link integration with secure beneficiary data sharing

class ExternalVendorService {
  async createOrder(orderData) {
    // 1. Generate secure, time-limited beneficiary data link
    const secureLink = await this.generateSecureBeneficiaryLink(
      orderData.seekerPhoto,
      orderData.seekerLocation,
      orderData.facialDescription
    );
    
    // 2. Generate deep link with embedded secure instructions
    const paymentLink = await this.generateVendorLink(
      'swiggy',
      orderData,
      secureLink
    );
    
    // 3. Return link for donor to complete order with vendor
    return { paymentLink, vendor: 'swiggy', secureLink };
  }
  
  async generateSecureBeneficiaryLink(photoUrl, location, description) {
    // Create encrypted, expiring link for delivery personnel
    // NDA-protected, one-time access
    return await this.createTimeLimitedAccessLink({
      photoUrl,
      location,
      description,
      expiresIn: '2 hours',
      accessType: 'delivery_personnel_only'
    });
  }
}
```

**Scale Phase (Months 7-12):**
```javascript
// Full API integration with multiple vendors
// Hybrid approach: Direct vendors + Platforms

class HybridVendorService {
  async createOrder(orderData) {
    // Intelligent routing based on cost, capacity, location
    const bestOption = await this.selectBestVendor(orderData);
    
    if (bestOption.type === 'direct') {
      return await this.directVendorService.createOrder(orderData);
    } else {
      return await this.externalVendorService.createOrder(orderData);
    }
  }
}
```

**Deliverables:**
- [ ] Direct vendor onboarding portal created
- [ ] Hourly capacity management implemented
- [ ] Vendor notification system working
- [ ] Logistics partner integration (Dunzo/Porter API)
- [ ] Partnership outreach initiated with Swiggy/Zomato

---

### **Week 9-10: Local Development Environment**

```bash
# Docker Compose for local full-stack testing
version: '3.8'
services:
  postgres:
    image: postgis/postgis:15-3.3-alpine
    environment:
      POSTGRES_DB: sharebridge
      POSTGRES_PASSWORD: dev123
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  api:
    build: ./backend
    ports:
      - "3000:3000"
    environment:
      DATABASE_URL: postgresql://postgres:dev123@postgres:5432/sharebridge
      REDIS_URL: redis://redis:6379
    depends_on:
      - postgres
      - redis

volumes:
  pgdata:
```

**Run locally:**
```bash
docker-compose up
# Everything runs on your machine - zero cloud costs
```

**Deliverables:**
- [ ] Docker Compose configured
- [ ] All services running locally
- [ ] Development workflow documented
- [ ] Seed data scripts ready
- [ ] Local testing guide created

---

## Phase 3: Testing & Integration (Months 5-6) - Free Tier

### **Week 1-2: End-to-End Testing**

**Testing Checklist:**
```markdown
### Functionality Testing
- [ ] End-to-end order flow (donor → delivery → seeker)
- [ ] Beneficiary assistance history working with test images
- [ ] Safety scoring calculations accurate
- [ ] Push notifications received on iOS/Android
- [ ] SMS OTP delivery working
- [ ] Email receipts delivered

### Performance Testing
- [ ] Load test API with 1K concurrent users (Locust/k6)
- [ ] Database query performance < 100ms (p95)
- [ ] Cache hit rate > 80%
- [ ] Photo upload/download < 2s

### Security Testing
- [ ] SQL injection tests passed
- [ ] XSS/CSRF protections working
- [ ] Authentication/authorization working
- [ ] Rate limiting prevents abuse
- [ ] Sensitive data encrypted at rest/transit

### Integration Testing
- [ ] Swiggy/Zomato/Uber Eats API integration tested
- [ ] Google Maps API working (geocoding, traffic, places)
- [ ] Payment gateway test transactions successful
- [ ] All third-party webhooks handling retries
```

---

### **Week 3-4: Documentation & Handoff**

**Deliverables:**
- [ ] API documentation complete (Swagger/OpenAPI)
- [ ] Database schema documented
- [ ] Environment setup guide
- [ ] Deployment runbooks
- [ ] Troubleshooting guide
- [ ] Migration scripts tested

---

## 🚀 Production Migration Plan

### Overview

Once all components are developed and tested on free platforms, migrate to production AWS infrastructure in **1 week**.

---

### **Pre-Migration Checklist**

```markdown
### Backend API
- [ ] All routes implemented and tested locally
- [ ] Database migrations ready
- [ ] Environment variables documented
- [ ] Docker image builds successfully
- [ ] API documentation complete (Swagger/OpenAPI)
- [ ] Unit tests passing (80%+ coverage)
- [ ] Integration tests with Supabase passing

### Database
- [ ] Schema finalized (no breaking changes expected)
- [ ] Indexes optimized
- [ ] Sample data seeded for testing
- [ ] Backup/restore procedures documented
- [ ] Migration scripts from Supabase → Production ready

### Storage
- [ ] All photo upload/delete flows tested
- [ ] Image optimization working (< 500KB)
- [ ] Cloudinary → S3 migration script ready
- [ ] CDN URLs can be swapped via env variable

### Caching
- [ ] Cache invalidation logic tested
- [ ] Redis keys documented
- [ ] Fallback to DB working when cache misses
- [ ] Upstash → ElastiCache migration script ready

### Message Queue
- [ ] Event schemas documented
- [ ] Producers and consumers tested
- [ ] Dead letter queue handling implemented
- [ ] Queue → AWS SQS migration script ready

### Third-Party Services
- [ ] Twilio upgraded to paid account
- [ ] Email service upgraded (Resend → SendGrid)
- [ ] Firebase FCM tested on real devices
- [ ] Google Maps API key with production quota
```

---

### **Migration Timeline**

#### **D-Day - 7: Database Migration**

```bash
# 1. Export from Supabase
pg_dump -h db.your-project.supabase.co -U postgres -d postgres \
  --schema=public --no-owner --no-acl > sharebridge_dump.sql

# 2. Create AWS RDS PostgreSQL instance
aws rds create-db-instance \
  --db-instance-identifier sharebridge-prod \
  --db-instance-class db.t3.medium \
  --engine postgres \
  --engine-version 15.3 \
  --master-username sharebridge \
  --master-user-password "YOUR_SECURE_PASSWORD" \
  --allocated-storage 100

# 3. Install PostGIS on RDS
psql -h sharebridge-prod.xyz.rds.amazonaws.com -U sharebridge -d postgres
CREATE EXTENSION postgis;
CREATE EXTENSION pgvector;

# 4. Import data
psql -h sharebridge-prod.xyz.rds.amazonaws.com -U sharebridge -d postgres \
  < sharebridge_dump.sql

# 5. Verify data integrity
SELECT COUNT(*) FROM users;
SELECT COUNT(*) FROM orders;
```

**Deliverables:**
- [ ] RDS instance created
- [ ] Data migrated successfully
- [ ] Integrity checks passed
- [ ] Connection pooling configured
- [ ] Backup automated

---

#### **D-Day - 5: File Storage Migration**

```bash
# Migrate photos from Cloudinary to AWS S3
npm install aws-sdk cloudinary

# migration-script.js
const AWS = require('aws-sdk');
const cloudinary = require('cloudinary').v2;
const s3 = new AWS.S3();

const migratePhotos = async () => {
  // 1. Get all Cloudinary URLs from database
  const photos = await db.query(
    'SELECT id, seeker_photo_url, delivery_photo_url FROM orders'
  );

  for (const photo of photos) {
    // 2. Download from Cloudinary
    const response = await fetch(photo.seeker_photo_url);
    const buffer = await response.buffer();

    // 3. Upload to S3
    const s3Key = `seekers/${photo.id}.jpg`;
    await s3.putObject({
      Bucket: 'sharebridge-photos-prod',
      Key: s3Key,
      Body: buffer,
      ContentType: 'image/jpeg'
    }).promise();

    // 4. Update database with S3 URL
    const s3Url = `https://sharebridge-photos-prod.s3.amazonaws.com/${s3Key}`;
    await db.query(
      'UPDATE orders SET seeker_photo_url = $1 WHERE id = $2',
      [s3Url, photo.id]
    );
  }
};
```

**Deliverables:**
- [ ] S3 bucket created
- [ ] CloudFront CDN configured
- [ ] Photos migrated
- [ ] Database URLs updated
- [ ] Access policies configured

---

#### **D-Day - 3: Backend Deployment**

**Option A: AWS EC2 (Manual control)**

```bash
# 1. Launch EC2 instance
aws ec2 run-instances \
  --image-id ami-0c55b159cbfafe1f0 \
  --instance-type t3.medium \
  --key-name sharebridge-prod \
  --security-group-ids sg-xxxxx

# 2. SSH and setup
ssh -i sharebridge-prod.pem ec2-user@your-ec2-ip

# Install Docker
sudo yum update -y
sudo yum install -y docker
sudo service docker start
sudo usermod -a -G docker ec2-user

# 3. Pull and run container
docker pull yourusername/sharebridge-api:latest
docker run -d \
  -p 80:3000 \
  -e DATABASE_URL=postgresql://sharebridge:pass@rds-endpoint/postgres \
  -e REDIS_URL=redis://elasticache-endpoint:6379 \
  -e AWS_S3_BUCKET=sharebridge-photos-prod \
  --name sharebridge-api \
  yourusername/sharebridge-api:latest
```

**Option B: AWS ECS (Serverless, auto-scaling)**

```bash
# 1. Create ECS cluster
aws ecs create-cluster --cluster-name sharebridge-prod

# 2. Push Docker image to ECR
aws ecr create-repository --repository-name sharebridge-api
docker tag sharebridge-api:latest 123456789.dkr.ecr.us-east-1.amazonaws.com/sharebridge-api
docker push 123456789.dkr.ecr.us-east-1.amazonaws.com/sharebridge-api

# 3. Create task definition (task-def.json)
{
  "family": "sharebridge-api",
  "containerDefinitions": [{
    "name": "api",
    "image": "123456789.dkr.ecr.us-east-1.amazonaws.com/sharebridge-api",
    "memory": 512,
    "cpu": 256,
    "essential": true,
    "portMappings": [{
      "containerPort": 3000,
      "protocol": "tcp"
    }],
    "environment": [
      {"name": "DATABASE_URL", "value": "postgresql://..."},
      {"name": "REDIS_URL", "value": "redis://..."}
    ]
  }]
}

# 4. Create service
aws ecs create-service \
  --cluster sharebridge-prod \
  --service-name api \
  --task-definition sharebridge-api \
  --desired-count 2 \
  --launch-type FARGATE
```

**Deliverables:**
- [ ] Backend deployed to AWS
- [ ] Auto-scaling configured
- [ ] Health checks passing
- [ ] Environment variables set
- [ ] Logging configured

---

#### **D-Day - 2: Cache & Queue Migration**

**Redis Cache:**
```bash
# 1. Create ElastiCache cluster
aws elasticache create-replication-group \
  --replication-group-id sharebridge-prod-redis \
  --engine redis \
  --cache-node-type cache.t3.micro \
  --num-cache-clusters 1

# 2. Update application env variable
REDIS_URL=redis://sharebridge-prod-redis.xxxxx.cache.amazonaws.com:6379

# 3. No data migration needed (cache starts fresh)
```

**Message Queue:**
```bash
# 1. Create SQS queues
aws sqs create-queue --queue-name sharebridge-order-created
aws sqs create-queue --queue-name sharebridge-order-completed

# 2. Update application code
# Replace Upstash Kafka with AWS SQS SDK
const AWS = require('aws-sdk');
const sqs = new AWS.SQS({ region: 'us-east-1' });

await sqs.sendMessage({
  QueueUrl: 'https://sqs.us-east-1.amazonaws.com/123456789/sharebridge-order-created',
  MessageBody: JSON.stringify({ orderId: '123' })
}).promise();
```

**Deliverables:**
- [ ] ElastiCache deployed
- [ ] SQS queues created
- [ ] Application code updated
- [ ] Queue consumers running
- [ ] Monitoring alerts configured

---

#### **D-Day: DNS & Traffic Switch**

```bash
# 1. Update DNS records (Route53 or your provider)
# Point api.sharebridge.com → AWS Load Balancer

# 2. Gradual traffic shift
# - 10% production traffic → new AWS setup
# - Monitor for 2 hours
# - If stable, increase to 50%
# - Monitor for 4 hours
# - If stable, switch 100%

# 3. Keep Render.com as fallback for 1 week
# - Don't delete free tier deployment immediately
# - Can quickly rollback if issues
```

**Deliverables:**
- [ ] DNS updated
- [ ] SSL certificate configured
- [ ] Load balancer working
- [ ] Traffic monitored
- [ ] Rollback plan ready

---

## Integration Architecture

### **Development (Free Tier)**

```
┌─────────────────────────────────────────────────────────────┐
│                    DEVELOPMENT (FREE)                        │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  GitHub (Code) → Railway/Render (API) → Supabase (DB)       │
│                         ↓                                     │
│                  Upstash (Cache)                             │
│                         ↓                                     │
│                  Cloudinary (Storage)                        │
│                         ↓                                     │
│              Firebase FCM (Push Notifications)               │
│                         ↓                                     │
│            Twilio Trial / Resend (SMS/Email)                 │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

### **Production (AWS)**

```
┌─────────────────────────────────────────────────────────────┐
│                   PRODUCTION (AWS/PAID)                      │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  GitHub Actions → AWS ECS (API) → AWS RDS (DB)              │
│                         ↓                                     │
│                  ElastiCache (Cache)                         │
│                         ↓                                     │
│                  AWS S3 + CloudFront (Storage)               │
│                         ↓                                     │
│              Firebase FCM (Push - unchanged)                 │
│                         ↓                                     │
│              Twilio Paid / SendGrid (SMS/Email)              │
│                         ↓                                     │
│            Route53 (DNS) + CloudFlare (DDoS)                 │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

---

## Cost Comparison

| Phase | Free Tier Development | AWS Production (Month 1) | AWS Production (Month 6) |
|-------|----------------------|-------------------------|-------------------------|
| **Database** | $0 (Supabase) | $50 (RDS t3.medium) | $750 (+ replicas) |
| **API Servers** | $0 (Render/Railway) | $70 (2x t3.small EC2) | $900 (3 regions) |
| **Storage** | $0 (Cloudinary) | $5 (S3 + CloudFront) | $300 (multi-region) |
| **Cache** | $0 (Upstash) | $15 (ElastiCache micro) | $600 (3 clusters) |
| **Queue** | $0 (Redis Pub/Sub) | $5 (SQS pay-per-use) | $50 (higher volume) |
| **SMS** | $0 (Not enabled) | $100 (1K SMS/month, if enabled) | $1000 (10K SMS, if enabled) |
| **Email** | $0 (Resend free) | $10 (SendGrid starter) | $50 (higher volume) |
| **Monitoring** | $0 (Sentry free) | $0 (CloudWatch free tier) | $100 (DataDog) |
| **TOTAL** | **$0/month** | **$255/month** | **$3,750/month** |

---

## 🌐 Production Scale Track (Optional - Multi-Region)

*Note: This section applies only if scaling to 100K+ orders/day across multiple continents. Skip this for initial launch.*
# AWS RDS Setup
aws rds create-db-instance-read-replica \
  --db-instance-identifier sharebridge-eu-west-replica \
  --source-db-instance-identifier sharebridge-primary \
  --region eu-west-1

aws rds create-db-instance-read-replica \
  --db-instance-identifier sharebridge-asia-south-replica \
  --source-db-instance-identifier sharebridge-primary \
  --region ap-south-1
```

**Deliverables:**
- [ ] Primary DB in US-East (existing)
- [ ] Read replica in EU-West (new)
- [ ] Read replica in Asia-South (new)
- [ ] Replication lag monitoring < 5 seconds
- [ ] Automated failover configuration

**Cost:** ~$750/month for 2 read replicas

---

#### Step 1.2: Deploy PgBouncer Connection Pooling
```bash
# Install PgBouncer on each application server
sudo apt-get install pgbouncer

# Configure /etc/pgbouncer/pgbouncer.ini
[databases]
sharebridge = host=sharebridge-primary.rds.amazonaws.com port=5432 dbname=sharebridge

[pgbouncer]
pool_mode = transaction
default_pool_size = 25
max_client_conn = 10000
max_db_connections = 100
```

**Application Changes:**
```javascript
// Before (direct connection)
const dbConfig = {
  host: 'sharebridge-primary.rds.amazonaws.com',
  port: 5432,
  database: 'sharebridge'
};

// After (through PgBouncer)
const dbConfig = {
  host: 'localhost',  // PgBouncer on same server
  port: 6432,         // PgBouncer port
  database: 'sharebridge'
};
```

**Deliverables:**
- [ ] PgBouncer deployed on all app servers
- [ ] Connection pool configuration tested
- [ ] Load testing: 10K concurrent connections
- [ ] Monitoring dashboards for pool metrics

**Impact:** Support 10K+ concurrent users (vs 200 currently)

---

### Week 3-4: Database Query Optimization

#### Step 1.3: Create Optimized Geospatial Indexes
```sql
-- Drop existing basic indexes
DROP INDEX IF EXISTS idx_orders_location;

-- Create specialized GiST index with buffering
CREATE INDEX idx_orders_location_gist 
ON orders USING GIST(location) 
WITH (buffering = on, fillfactor = 90);

-- Partial index for active orders (80% query reduction)
CREATE INDEX idx_active_orders_location 
ON orders USING GIST(location)
WHERE status IN ('created', 'in_transit', 'confirmed');

-- BRIN index for time-series queries
CREATE INDEX idx_orders_location_brin 
ON orders USING BRIN(location, created_at);

-- Analyze for query planner
ANALYZE orders;
```

**Query Optimization:**
```sql
-- Before (slow - sequential scan)
SELECT * FROM orders 
WHERE ST_Distance(location, ST_MakePoint(77.5946, 12.9716)) < 1000;

-- After (fast - index scan)
SELECT * FROM orders 
WHERE status IN ('created', 'in_transit')
  AND created_at > NOW() - INTERVAL '24 hours'
  AND location && ST_Expand(ST_MakePoint(77.5946, 12.9716)::geography, 1000)
  AND ST_DWithin(location, ST_MakePoint(77.5946, 12.9716)::geography, 1000)
ORDER BY created_at DESC
LIMIT 20;
```

**Deliverables:**
- [ ] All geospatial indexes created
- [ ] Query performance benchmarked (before/after)
- [ ] Slow query log analysis (identify queries > 1s)
- [ ] Query optimization guide for developers

**Performance Gain:** 10x-50x faster geospatial queries

---

#### Step 1.4: PostgreSQL Configuration Tuning
```sql
-- Edit postgresql.conf
shared_buffers = 8GB                    -- 25% of RAM
effective_cache_size = 24GB             -- 75% of RAM
maintenance_work_mem = 2GB
work_mem = 64MB
max_connections = 200
random_page_cost = 1.1                  -- SSD storage
max_parallel_workers_per_gather = 4
max_parallel_workers = 8
autovacuum_max_workers = 4
autovacuum_naptime = 30s
log_min_duration_statement = 1000       -- Log slow queries

-- Restart PostgreSQL
sudo systemctl restart postgresql
```

**Deliverables:**
- [ ] Configuration changes applied and tested
- [ ] Benchmark before/after performance
- [ ] Monitoring alerts for slow queries
- [ ] Documentation of tuning parameters

---

### Week 5-6: Regional Caching Infrastructure

#### Step 1.5: Deploy Regional Redis Clusters
```bash
# AWS ElastiCache Redis Clusters
aws elasticache create-replication-group \
  --replication-group-id sharebridge-us-east-redis \
  --replication-group-description "US East Redis Cluster" \
  --engine redis \
  --cache-node-type cache.r6g.large \
  --num-cache-clusters 3 \
  --automatic-failover-enabled

# Repeat for EU-West and Asia-South
```

**Application Integration:**
```javascript
// Regional Redis routing
const Redis = require('ioredis');

const redisClients = {
  'us-east': new Redis.Cluster([
    { host: 'redis-us-east-1.cache.amazonaws.com', port: 6379 },
    { host: 'redis-us-east-2.cache.amazonaws.com', port: 6379 },
    { host: 'redis-us-east-3.cache.amazonaws.com', port: 6379 }
  ]),
  'eu-west': new Redis.Cluster([...]),
  'asia-south': new Redis.Cluster([...])
};

function getRedisClient(userRegion) {
  return redisClients[userRegion] || redisClients['us-east'];
}
```

**Deliverables:**
- [ ] Redis clusters in 3 regions
- [ ] Regional routing logic implemented
- [ ] Cache warming scripts for hot data
- [ ] Cache hit rate monitoring (target: 85%+)

**Cost:** ~$600/month for 3 regional clusters

---

#### Step 1.6: Implement Geospatial Caching
```javascript
// Cache seekers in Redis geospatial index
async function cacheSeeker(seekerId, lat, lng) {
  const redis = getRedisClient(userRegion);
  await redis.geoadd('seekers:active', lng, lat, seekerId);
  await redis.expire('seekers:active', 7200); // 2 hours
}

// Fast nearby search (in-memory)
async function findNearbySeekers(lat, lng, radiusKm) {
  const redis = getRedisClient(userRegion);
  
  // Try cache first
  const cached = await redis.georadius('seekers:active', 
    lng, lat, radiusKm, 'km', 'WITHDIST', 'COUNT', 10);
  
  if (cached.length > 0) return cached;
  
  // Fallback to PostgreSQL
  return await db.query(`
    SELECT * FROM orders 
    WHERE status IN ('created', 'in_transit')
      AND ST_DWithin(location, ST_MakePoint($1, $2)::geography, $3)
    LIMIT 10
  `, [lng, lat, radiusKm * 1000]);
}
```

**Deliverables:**
- [ ] Geospatial cache implementation
- [ ] Cache invalidation on order completion
- [ ] Performance benchmarks (cache vs DB)
- [ ] Cache monitoring dashboards

**Performance Gain:** < 10ms for nearby searches (vs 100ms+)

---

### Week 7-8: CDN and Photo Storage

#### Step 1.7: Set Up CloudFront CDN
```bash
# Create S3 buckets in each region
aws s3 mb s3://sharebridge-photos-us-east --region us-east-1
aws s3 mb s3://sharebridge-photos-eu-west --region eu-west-1
aws s3 mb s3://sharebridge-photos-asia-south --region ap-south-1

# Enable cross-region replication
aws s3api put-bucket-replication \
  --bucket sharebridge-photos-us-east \
  --replication-configuration file://replication-config.json
```

**CloudFront Configuration:**
```json
{
  "Origins": [
    {
      "Id": "S3-us-east",
      "DomainName": "sharebridge-photos-us-east.s3.amazonaws.com",
      "OriginPath": "",
      "CustomHeaders": []
    },
    {
      "Id": "S3-eu-west",
      "DomainName": "sharebridge-photos-eu-west.s3.amazonaws.com"
    }
  ],
  "DefaultCacheBehavior": {
    "TargetOriginId": "S3-us-east",
    "ViewerProtocolPolicy": "redirect-to-https",
    "AllowedMethods": ["GET", "HEAD"],
    "CachedMethods": ["GET", "HEAD"],
    "MinTTL": 86400,
    "Compress": true,
    "OriginRequestPolicyId": "failover-policy"
  }
}
```

**Application Changes:**
```javascript
// Photo upload to nearest region
async function uploadPhoto(photo, userLocation) {
  const nearestRegion = determineNearestRegion(userLocation);
  const bucket = `sharebridge-photos-${nearestRegion}`;
  
  // Get pre-signed URL
  const uploadUrl = s3.getSignedUrl('putObject', {
    Bucket: bucket,
    Key: `uploads/${Date.now()}-${photo.name}`,
    ContentType: photo.type,
    Expires: 300
  });
  
  return uploadUrl;
}
```

**Deliverables:**
- [ ] S3 buckets in 3 regions
- [ ] Cross-region replication enabled
- [ ] CloudFront distribution configured
- [ ] Photo upload/download tested globally
- [ ] Lifecycle policy (delete after 30 days)

**Cost:** ~$300/month for storage + CDN

---

## Phase 2: Global Routing (Month 3)

### Objectives
- Deploy API gateways in multiple regions
- Implement geographic routing
- Set up distributed rate limiting
- Configure cross-region monitoring

### Week 9-10: Multi-Region API Deployment

#### Step 2.1: Deploy Services to Multiple Regions
```yaml
# Kubernetes deployment manifest
apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-service
  namespace: sharebridge-us-east
spec:
  replicas: 3
  selector:
    matchLabels:
      app: order-service
      region: us-east
  template:
    spec:
      containers:
      - name: order-service
        image: sharebridge/order-service:1.0.0
        env:
        - name: DB_HOST
          value: localhost:6432  # PgBouncer
        - name: DB_REPLICA
          value: sharebridge-us-east-replica
        - name: REDIS_CLUSTER
          value: redis-us-east-cluster
        - name: AWS_REGION
          value: us-east-1
```

**Deployment Strategy:**
```bash
# Deploy to US-East (existing)
kubectl apply -f k8s/us-east/ --context us-east-cluster

# Deploy to EU-West (new)
kubectl apply -f k8s/eu-west/ --context eu-west-cluster

# Deploy to Asia-South (new)
kubectl apply -f k8s/asia-south/ --context asia-south-cluster
```

**Deliverables:**
- [ ] Services deployed in US-East
- [ ] Services deployed in EU-West
- [ ] Services deployed in Asia-South
- [ ] Health checks configured for all regions
- [ ] Auto-scaling policies per region

**Cost:** ~$900/month for compute (3 regions)

---

#### Step 2.2: Configure Route53 Geolocation Routing
```json
{
  "HostedZoneId": "Z1234567890ABC",
  "ChangeBatch": {
    "Changes": [
      {
        "Action": "CREATE",
        "ResourceRecordSet": {
          "Name": "api.sharebridge.com",
          "Type": "A",
          "GeoLocation": {
            "ContinentCode": "NA"
          },
          "SetIdentifier": "US-East",
          "AliasTarget": {
            "HostedZoneId": "Z35SXDOTRQ7X7K",
            "DNSName": "api-us-east-lb.amazonaws.com",
            "EvaluateTargetHealth": true
          }
        }
      },
      {
        "Action": "CREATE",
        "ResourceRecordSet": {
          "Name": "api.sharebridge.com",
          "Type": "A",
          "GeoLocation": {
            "ContinentCode": "EU"
          },
          "SetIdentifier": "EU-West",
          "AliasTarget": {
            "DNSName": "api-eu-west-lb.amazonaws.com"
          }
        }
      },
      {
        "Action": "CREATE",
        "ResourceRecordSet": {
          "Name": "api.sharebridge.com",
          "Type": "A",
          "GeoLocation": {
            "ContinentCode": "AS"
          },
          "SetIdentifier": "Asia-South",
          "AliasTarget": {
            "DNSName": "api-asia-south-lb.amazonaws.com"
          }
        }
      }
    ]
  }
}
```

**Health Check Configuration:**
```bash
aws route53 create-health-check \
  --health-check-config \
    IPAddress=<api-us-east-ip>,Port=443,Type=HTTPS,ResourcePath=/health \
  --caller-reference us-east-health-$(date +%s)
```

**Deliverables:**
- [ ] Route53 geolocation policies configured
- [ ] Health checks for all regional endpoints
- [ ] Failover to nearest healthy region
- [ ] DNS propagation tested globally

---

### Week 11-12: Rate Limiting and Security

#### Step 2.3: Implement Distributed Rate Limiting
```javascript
const RateLimiter = require('rate-limiter-flexible');

// Global rate limiter (across all regions)
const globalLimiter = new RateLimiter.RateLimiterRedis({
  storeClient: redisClusterGlobal,
  keyPrefix: 'rl_global',
  points: 1000,      // 1000 requests
  duration: 60,      // per minute
  blockDuration: 300 // block 5 min if exceeded
});

// Regional rate limiter
const regionalLimiter = new RateLimiter.RateLimiterRedis({
  storeClient: getRedisClient(userRegion),
  keyPrefix: 'rl_regional',
  points: 100,
  duration: 60
});

// Endpoint-specific limiter
const orderCreateLimiter = new RateLimiter.RateLimiterRedis({
  storeClient: getRedisClient(userRegion),
  keyPrefix: 'rl_order_create',
  points: 10,        // Max 10 orders
  duration: 3600,    // per hour
  blockDuration: 3600
});

// Middleware
app.use(async (req, res, next) => {
  try {
    await globalLimiter.consume(req.user.id);
    await regionalLimiter.consume(`${req.user.id}_${req.region}`);
    
    if (req.path === '/api/v1/orders') {
      await orderCreateLimiter.consume(req.user.id);
    }
    
    next();
  } catch (error) {
    res.status(429).json({
      error: 'RATE_LIMIT_EXCEEDED',
      retryAfter: error.msBeforeNext / 1000
    });
  }
});
```

**Deliverables:**
- [ ] Rate limiting implemented globally
- [ ] Rate limit monitoring dashboards
- [ ] Abuse detection alerts
- [ ] Rate limit testing (load tests)

---

## Phase 3: Data Distribution (Month 4)

### Objectives
- Enable S3 cross-region replication
- Implement cache invalidation strategy
- Optimize photo upload/download paths
- Configure regional message queues

### Week 13-14: Advanced Caching

#### Step 3.1: Cache Invalidation Strategy
```javascript
const EventEmitter = require('events');
const cacheInvalidator = new EventEmitter();

// Invalidate across all regions when order updates
cacheInvalidator.on('order:updated', async (orderId) => {
  await Promise.all([
    redisUSEast.del(`order:${orderId}`),
    redisEUWest.del(`order:${orderId}`),
    redisAsiaSouth.del(`order:${orderId}`)
  ]);
  
  // Also invalidate CloudFront if order has photos
  const order = await db.orders.findById(orderId);
  if (order.photos) {
    await cloudfront.createInvalidation({
      DistributionId: 'EXXXXXXXXXXXXX',
      InvalidationBatch: {
        Paths: { Items: order.photos },
        CallerReference: `order-${orderId}-${Date.now()}`
      }
    });
  }
});

// Publish event on order update
async function updateOrder(orderId, updates) {
  await db.orders.update(orderId, updates);
  cacheInvalidator.emit('order:updated', orderId);
}
```

**Deliverables:**
- [ ] Event-driven cache invalidation
- [ ] CloudFront invalidation for photos
- [ ] Cache consistency monitoring
- [ ] Invalidation performance metrics

---

#### Step 3.2: Database Query Result Caching
```javascript
// Cache frequently accessed data
async function getOrder(orderId, userRegion) {
  const redis = getRedisClient(userRegion);
  const cacheKey = `order:${orderId}`;
  
  // Try cache first
  const cached = await redis.get(cacheKey);
  if (cached) return JSON.parse(cached);
  
  // Cache miss - query DB (nearest replica)
  const dbReplica = getDBReplica(userRegion);
  const order = await dbReplica.query(
    'SELECT * FROM orders WHERE id = $1',
    [orderId]
  );
  
  // Cache for 1 hour
  await redis.setex(cacheKey, 3600, JSON.stringify(order));
  
  return order;
}

function getDBReplica(region) {
  const replicas = {
    'us-east': 'sharebridge-us-east-replica',
    'eu-west': 'sharebridge-eu-west-replica',
    'asia-south': 'sharebridge-asia-south-replica'
  };
  return db.connect(replicas[region]);
}
```

**Deliverables:**
- [ ] Query result caching implemented
- [ ] Read routing to nearest replica
- [ ] Cache hit rate > 85%
- [ ] Cache performance dashboards

---

### Week 15-16: Message Queue Migration

#### Step 3.3: Migrate from RabbitMQ to AWS SQS/SNS
```javascript
// Before: RabbitMQ (single region)
const amqp = require('amqplib');
const connection = await amqp.connect('amqp://localhost');
const channel = await connection.createChannel();

// After: AWS SQS (multi-region)
const AWS = require('aws-sdk');
const sqs = new AWS.SQS({ region: userRegion });

// Send message to regional queue
async function sendOrderCreatedEvent(order) {
  const queueUrl = getQueueUrl('order-created', order.region);
  
  await sqs.sendMessage({
    QueueUrl: queueUrl,
    MessageBody: JSON.stringify(order),
    MessageAttributes: {
      region: { DataType: 'String', StringValue: order.region },
      priority: { DataType: 'String', StringValue: 'high' }
    }
  }).promise();
}

// Also publish to SNS for cross-region fanout
async function publishGlobalEvent(eventType, data) {
  const sns = new AWS.SNS({ region: 'us-east-1' });
  
  await sns.publish({
    TopicArn: `arn:aws:sns:us-east-1:123456789:sharebridge-${eventType}`,
    Message: JSON.stringify(data),
    MessageAttributes: {
      eventType: { DataType: 'String', StringValue: eventType }
    }
  }).promise();
}
```

**Queue Setup:**
```bash
# Create queues in each region
aws sqs create-queue --queue-name sharebridge-order-created --region us-east-1
aws sqs create-queue --queue-name sharebridge-order-created --region eu-west-1
aws sqs create-queue --queue-name sharebridge-order-created --region ap-south-1

# Create SNS topic for cross-region events
aws sns create-topic --name sharebridge-global-events --region us-east-1

# Subscribe regional SQS queues to SNS topic
aws sns subscribe \
  --topic-arn arn:aws:sns:us-east-1:123456789:sharebridge-global-events \
  --protocol sqs \
  --notification-endpoint arn:aws:sqs:us-east-1:123456789:sharebridge-order-created
```

**Deliverables:**
- [ ] SQS queues in 3 regions
- [ ] SNS topics for global events
- [ ] Queue subscriptions configured
- [ ] Message consumers migrated
- [ ] Dead letter queues configured
- [ ] RabbitMQ gracefully decommissioned

**Cost Savings:** $200/month (RabbitMQ ops) → $5/month (SQS)

---

## Phase 4: Testing & Optimization (Months 5-6)

### Objectives
- Load testing from multiple geographic locations
- Latency benchmarking and optimization
- Failover testing and disaster recovery
- Cost optimization
- Performance tuning

### Week 17-18: Load Testing

#### Step 4.1: Global Load Testing
```javascript
// k6 load testing script
import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
  stages: [
    { duration: '5m', target: 100 },   // Ramp to 100 users
    { duration: '10m', target: 1000 }, // Ramp to 1000 users
    { duration: '10m', target: 5000 }, // Peak load
    { duration: '5m', target: 0 }      // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<200', 'p(99)<500'], // 95% < 200ms
    http_req_failed: ['rate<0.01']                  // Error rate < 1%
  }
};

export default function() {
  // Test order creation
  const createOrderRes = http.post(
    'https://api.sharebridge.com/api/v1/orders',
    JSON.stringify({
      location: { lat: 12.9716, lng: 77.5946 },
      items: [{ name: 'Meal', quantity: 1 }]
    }),
    { headers: { 'Content-Type': 'application/json' } }
  );
  
  check(createOrderRes, {
    'order created': (r) => r.status === 201,
    'response time OK': (r) => r.timings.duration < 2000
  });
  
  sleep(1);
}
```

**Testing Matrix:**
| Location | Users | Target Latency | Success Rate |
|----------|-------|----------------|--------------|
| US-East | 2000 | < 150ms | > 99.9% |
| EU-West | 1500 | < 150ms | > 99.9% |
| Asia-South | 2500 | < 150ms | > 99.9% |

**Deliverables:**
- [ ] Load tests from 3 continents
- [ ] Performance benchmarks documented
- [ ] Bottlenecks identified and resolved
- [ ] Capacity planning recommendations

---

### Week 19-20: Failover Testing

#### Step 4.2: Disaster Recovery Drills
```bash
# Test 1: Primary database failover
aws rds failover-db-cluster --db-cluster-identifier sharebridge-primary

# Test 2: Regional API failure
# Simulate US-East region failure
aws ec2 stop-instances --instance-ids $(kubectl get nodes -o jsonpath='{.items[*].spec.providerID}' --context us-east)

# Verify traffic reroutes to EU-West
dig api.sharebridge.com @8.8.8.8

# Test 3: Cache cluster failure
aws elasticache test-failover --replication-group-id sharebridge-us-east-redis --node-group-id 0001
```

**Failover Scenarios:**
1. Database primary failure → Promote replica
2. Regional API outage → Route53 health check failover
3. Redis cluster failure → Automatic failover to standby
4. S3 bucket unavailable → CloudFront origin failover

**Deliverables:**
- [ ] All failover scenarios tested
- [ ] RTO measured: < 4 hours
- [ ] RPO measured: < 1 hour
- [ ] Runbook for disaster recovery
- [ ] On-call procedures documented

---

### Week 21-22: Performance Optimization

#### Step 4.3: Query Optimization Round 2
```sql
-- Identify slow queries from logs
SELECT 
  query,
  calls,
  mean_exec_time,
  max_exec_time
FROM pg_stat_statements
WHERE mean_exec_time > 100
ORDER BY mean_exec_time DESC
LIMIT 20;

-- Add missing indexes
CREATE INDEX idx_orders_donor_created 
ON orders(donor_id, created_at DESC);

-- Materialized view for hot data
CREATE MATERIALIZED VIEW recent_orders AS
SELECT * FROM orders 
WHERE created_at > NOW() - INTERVAL '7 days';

REFRESH MATERIALIZED VIEW CONCURRENTLY recent_orders;
```

**Deliverables:**
- [ ] All queries optimized (< 50ms p95)
- [ ] Materialized views for dashboards
- [ ] Index usage analysis
- [ ] Query performance dashboard

---

### Week 23-24: Cost Optimization

#### Step 4.4: Infrastructure Cost Optimization
```yaml
Optimization Strategies:
  1. Reserved Instances:
     - RDS: 1-year RI → 40% savings ($600/mo → $360/mo)
     - EC2: 1-year RI → 40% savings ($900/mo → $540/mo)
  
  2. Auto-Scaling:
     - Scale down 70% during off-peak (2AM-6AM)
     - Use Spot instances for batch jobs (70% savings)
  
  3. Storage:
     - S3 Intelligent Tiering (30% savings on older photos)
     - Enable gzip/brotli on CloudFront (reduce bandwidth 60%)
  
  4. Database:
     - Optimize IOPS allocation (reduce from provisioned to GP3)
     - Archive old orders to cheaper storage
  
  5. Monitoring:
     - Right-size CloudWatch log retention (90 days → 30 days)
     - Use sampling for detailed traces (100% → 10%)

Expected Savings: $1,200/month (25% reduction)
```

**Deliverables:**
- [ ] Reserved instances purchased
- [ ] Auto-scaling optimized
- [ ] Storage lifecycle policies configured
- [ ] Monthly cost reports
- [ ] Cost anomaly alerts

---

## Success Metrics

### Performance Metrics
| Metric | Before | Target | Actual |
|--------|--------|--------|--------|
| API Latency (p95) - Global | 300-500ms | < 150ms | ___ |
| Database Query (p95) | 100ms | < 30ms | ___ |
| Photo Upload Time | 5-10s | < 2s | ___ |
| Cache Hit Rate | 60% | > 85% | ___ |
| Geospatial Query | 200ms | < 50ms | ___ |
| Uptime | 99.5% | 99.99% | ___ |

### Scalability Metrics
| Metric | Before | Target | Actual |
|--------|--------|--------|--------|
| Concurrent Users | 200 | 10,000 | ___ |
| Orders/Day | 500 | 100,000 | ___ |
| Database Connections | 200 | 100 (pooled) | ___ |
| Regions | 1 | 3 | ___ |

### Cost Metrics
| Component | Month 1 | Month 6 | Optimized |
|-----------|---------|---------|-----------|
| Database | $500 | $1,450 | $900 |
| Cache | $0 | $600 | $450 |
| Compute | $400 | $900 | $550 |
| Storage | $50 | $362 | $250 |
| **Total** | **$950** | **$3,312** | **$2,150** |

---

## Risk Mitigation

### Technical Risks
| Risk | Impact | Mitigation |
|------|--------|------------|
| Replication lag > 5s | High | Monitor lag, alert at 3s, promote if > 10s |
| Cross-region latency | Medium | Cache aggressively, optimize queries |
| Cache stampede | High | Use lock mechanisms, stagger TTLs |
| Database connection exhaustion | High | PgBouncer pooling, connection monitoring |

### Operational Risks
| Risk | Impact | Mitigation |
|------|--------|------------|
| Regional outage | High | Multi-region deployment, health checks |
| Cost overrun | Medium | Budget alerts, auto-scaling limits |
| Data inconsistency | High | Transaction logs, reconciliation jobs |
| Team knowledge gap | Medium | Documentation, training, runbooks |

---

## Rollback Plan

### Rollback Strategy
```bash
# Phase 1 Rollback: Remove read replicas
aws rds delete-db-instance --db-instance-identifier sharebridge-eu-west-replica
aws rds delete-db-instance --db-instance-identifier sharebridge-asia-south-replica

# Phase 2 Rollback: Revert to single region
aws route53 change-resource-record-sets --hosted-zone-id Z123 --change-batch file://rollback-dns.json

# Phase 3 Rollback: Revert to RabbitMQ
kubectl apply -f k8s/rabbitmq-deployment.yaml

# Database Rollback: Drop new indexes (if causing issues)
DROP INDEX CONCURRENTLY idx_orders_location_gist;
```

**Rollback Triggers:**
- Error rate > 5% for 10 minutes
- Latency degradation > 50%
- Cost overrun > 150% of budget
- Data corruption detected

---

## Documentation Requirements

### Phase 1 Documentation
- [ ] Database architecture diagram
- [ ] PgBouncer configuration guide
- [ ] Index optimization playbook
- [ ] Cache strategy documentation

### Phase 2 Documentation
- [ ] Multi-region deployment guide
- [ ] DNS routing configuration
- [ ] Rate limiting policies
- [ ] Security best practices

### Phase 3 Documentation
- [ ] Cache invalidation procedures
- [ ] Message queue migration guide
- [ ] Photo storage architecture
- [ ] Data consistency checks

### Phase 4 Documentation
- [ ] Load testing procedures
- [ ] Disaster recovery runbook
- [ ] Performance tuning guide
- [ ] Cost optimization checklist

---

## Team Responsibilities

### Backend Team (2 engineers)
- Database migration and optimization
- API deployment to multiple regions
- Cache implementation
- Message queue migration

### DevOps Team (1 engineer)
- Infrastructure provisioning (RDS, Redis, EKS)
- CI/CD pipeline updates
- Monitoring and alerting
- Disaster recovery procedures

### Frontend Team (1 engineer)
- Regional endpoint routing
- Photo upload optimization
- Error handling for multi-region
- Performance monitoring

### QA Team (1 engineer)
- Load testing
- Failover testing
- Regional testing
- Performance validation

---

## Next Steps

1. **Week 1:** Kickoff meeting, assign responsibilities
2. **Week 1:** Provision RDS read replicas (US-East → EU-West, Asia-South)
3. **Week 2:** Deploy PgBouncer, begin connection pooling
4. **Week 3:** Create optimized geospatial indexes
5. **Week 4:** Deploy regional Redis clusters
6. **Week 5:** Begin Phase 2 (multi-region API deployment)

---

## Support & Resources

### Free Tier Platforms
- **Supabase:** https://supabase.com/docs
- **Render:** https://render.com/docs
- **Railway:** https://docs.railway.app
- **Upstash:** https://docs.upstash.com
- **Cloudinary:** https://cloudinary.com/documentation
- **Firebase:** https://firebase.google.com/docs
- **Resend:** https://resend.com/docs

### AWS Resources (Production)
- **RDS Documentation:** https://docs.aws.amazon.com/rds/
- **ECS Documentation:** https://docs.aws.amazon.com/ecs/
- **S3 Documentation:** https://docs.aws.amazon.com/s3/
- **ElastiCache:** https://docs.aws.amazon.com/elasticache/

---

**Document Owner:** VKK  
**Last Updated:** January 7, 2026  
**Review Frequency:** Weekly during implementation  
