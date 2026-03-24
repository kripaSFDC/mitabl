# mitabl — Project Overview

**Generated:** 2026-03-14 | **Scan Level:** Exhaustive | **Document Language:** English

---

## Executive Summary

mitabl is a home-cooked food marketplace platform that connects **Foodies** (customers) with **Cooks** operating virtual kitchens called **miKitchens**. The platform enables discovery, ordering, payment processing, and fulfillment of home-cooked meals, with a comprehensive admin panel for operations management.

The codebase is organized as a **monorepo** with three application parts and deployment infrastructure.

---

## Repository Structure

| Part | Path | Type | Primary Technology |
|------|------|------|-------------------|
| **Backend** | `backend/` | API + Admin Panel | Laravel 12 (PHP 8.2), MySQL 8.0, Redis 7.2, Filament 3 |
| **Mobile App** | `mobile-app/` | iOS/Android App | Flutter (Dart SDK >=3.5.0), BLoC Pattern, Firebase |
| **Website** | `website/` | Static Marketing Site | HTML/CSS/JS, Bootstrap 4, Node.js Build, Nginx |
| **Deploy** | `deploy/` | Infrastructure | Docker Compose, Nginx, k6 Load Tests |

---

## Architecture Type

- **Repository Type:** Monorepo
- **Architecture Pattern:** Client-Server with API Gateway
- **API Style:** RESTful JSON API (JWT-authenticated)
- **Admin Panel:** Filament 3 (server-rendered, separate auth guard)
- **Database:** MySQL 8.0 (relational)
- **Cache/Queue:** Redis 7.2 with Laravel Horizon
- **Deployment:** Docker Compose on Contabo VPS (single-host)

---

## Technology Stack Summary

### Backend
| Category | Technology | Version |
|----------|-----------|---------|
| Language | PHP | 8.2 |
| Framework | Laravel | 12.1 |
| Database | MySQL | 8.0 |
| Cache/Queue | Redis | 7.2 |
| Queue Dashboard | Laravel Horizon | 5.45 |
| Admin Panel | Filament | 3.0 |
| API Auth | JWT (tymon/jwt-auth) | 2.2 |
| RBAC | spatie/laravel-permission | 6.7 |
| Payments | Stripe (stripe-php) | 8.1 |
| API Docs | L5 Swagger | 10.1 |
| Auditing | laravel-auditing | 14.0 |
| Testing | PHPUnit | 11.5 |

### Mobile App
| Category | Technology | Version |
|----------|-----------|---------|
| Framework | Flutter | SDK >=3.5.0 |
| Language | Dart | >=3.5.0 |
| State Management | flutter_bloc / Cubit | 9.0.0 |
| HTTP Client | http | 1.2.2 |
| Auth Storage | flutter_secure_storage | 10.0.0 |
| Push Notifications | Firebase Messaging | 15.1.3 |
| Biometrics | local_auth | 2.3.0 |
| Deep Linking | app_links | 6.3.2 |
| Geolocation | geolocator | 14.0.2 |
| Testing | flutter_test + bloc_test + mocktail | - |

### Website
| Category | Technology | Version |
|----------|-----------|---------|
| Framework | Custom Node.js SSG | - |
| CSS | Bootstrap | 4.6.1 |
| Fonts | Adobe Typekit (ITC Avant Garde) | - |
| Serving | Nginx | 1.27 |

### Infrastructure
| Category | Technology | Version |
|----------|-----------|---------|
| Containerization | Docker / Docker Compose | - |
| Reverse Proxy | Nginx | 1.27 |
| SSL | Let's Encrypt | - |
| CI/CD | GitHub Actions | - |
| Load Testing | k6 | - |
| Hosting | Contabo VPS | - |

---

## Product Personas

| Persona | Guard/Middleware | Capabilities |
|---------|-----------------|-------------|
| **Guest** | None | Public website, login, register, support tickets |
| **Foodie** (Customer) | `auth:api` + `customer` | Discovery, favorites, ordering, payments, reviews |
| **Cook** (Restaurant) | `auth:api` + `restaurant` | Kitchen/menu management, bookings, order fulfillment |
| **Admin** (super_admin) | `admin` guard | Full platform control, IAM, finance, governance |
| **Admin** (platform_admin) | `admin` guard | Settings, policies, templates, queue/health ops |
| **Admin** (operations) | `admin` guard | Kitchen/certificate/order/promo/support management |
| **Admin** (customer_service) | `admin` guard | User/ticket handling, order visibility |
| **Admin** (finance_readonly) | `admin` guard | Payment/order/audit read-only access |

---

## Key Domain Entities

### Core Marketplace
- **User** — Platform user (Foodie or Cook)
- **Mikitchn** — Virtual kitchen operated by a Cook
- **Foods** — Menu items within a kitchen
- **Order** / **OrderData** — Customer orders with line items
- **Review** — Bi-directional ratings (customer↔kitchen)
- **Favorite** — Customer kitchen favorites
- **PromoCode** — Discount codes with date ranges

### Payments & Settlement
- **Payment** — Order payment records
- **StripeAccount** — Customer/vendor Stripe accounts
- **Card** — Saved payment methods
- **Refund** — Order refund records
- **Transfer** — Vendor payout records

### CRM & Support
- **SupportTicket** — Full lifecycle support tickets with SLA
- **SupportTicketMessage** — Ticket conversation thread
- **SupportTicketAttachment** — File attachments with malware scanning
- **SupportTicketEvent** — Immutable ticket event timeline
- **CrmCommunicationLog** — Email delivery tracking

### Platform Governance
- **AdminUser** — Admin panel users (separate from API users)
- **AdminActionLog** — Immutable admin audit trail
- **Policy** — Versioned platform policies
- **PlatformSetting** — Runtime configuration
- **Template** — Communication templates

---

## Integration Points

| From | To | Type | Description |
|------|----|------|-------------|
| Mobile App | Backend API | REST/JSON + JWT | All data operations |
| Website (Contact Form) | Backend API | REST/JSON | Support ticket creation via `/api/support/ticket` |
| Backend | Stripe API | REST | Payment processing, refunds, transfers |
| Backend | Firebase | FCM | Push notifications to mobile |
| Backend | SMTP | Email | OTP, invoices, notifications, CRM communications |
| Admin Panel | Backend | Server-rendered (Filament) | Direct database/service access |

---

## Links to Detailed Documentation

- [Source Tree Analysis](./source-tree-analysis.md)
- [Architecture — Backend](./architecture-backend.md)
- [Architecture — Mobile App](./architecture-mobile-app.md)
- [Architecture — Website](./architecture-website.md)
- [API Contracts — Backend](./api-contracts-backend.md)
- [Data Models — Backend](./data-models-backend.md)
- [Component Inventory — Mobile App](./component-inventory-mobile-app.md)
- [Development Guide — Backend](./development-guide-backend.md)
- [Development Guide — Mobile App](./development-guide-mobile-app.md)
- [Development Guide — Website](./development-guide-website.md)
- [Deployment Guide](./deployment-guide.md)
- [Integration Architecture](./integration-architecture.md)
