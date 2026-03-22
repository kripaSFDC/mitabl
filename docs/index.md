# mitabl — Project Documentation Index

**Generated:** 2026-03-14 | **Scan Level:** Exhaustive | **Workflow:** initial_scan

---

## Project Overview

- **Type:** Monorepo with 3 application parts
- **Domain:** Home-cooked food marketplace (Foodies + Cooks + miKitchens)
- **Primary Languages:** PHP 8.2 (backend), Dart/Flutter (mobile), HTML/CSS/JS (website)
- **Architecture:** Client-Server with REST/JSON API, JWT authentication

### Quick Reference

#### Backend (`backend/`)
- **Type:** API + Admin Panel
- **Tech Stack:** Laravel 12, MySQL 8.0, Redis 7.2, Filament 3, Stripe
- **Root:** `backend/`
- **Entry Point:** `backend/routes/api.php`
- **Architecture Pattern:** Layered with Service Layer

#### Mobile App (`mobile-app/`)
- **Type:** Cross-platform mobile app (iOS + Android)
- **Tech Stack:** Flutter (Dart SDK >=3.5.0), BLoC/Cubit, Firebase
- **Root:** `mobile-app/`
- **Entry Point:** `mobile-app/lib/main.dart`
- **Architecture Pattern:** BLoC/Cubit with Repository Pattern

#### Website (`website/`)
- **Type:** Static marketing site
- **Tech Stack:** Custom Node.js SSG, Bootstrap 4, Nginx
- **Root:** `website/`
- **Entry Point:** `website/build-static-site.js`
- **Architecture Pattern:** Static site generation with shared templates

---

## Generated Documentation

### Project-Wide
- [Project Overview](./project-overview.md) — Executive summary, tech stack, personas, domain entities
- [Source Tree Analysis](./source-tree-analysis.md) — Annotated directory tree with entry points and critical files
- [Integration Architecture](./integration-architecture.md) — How parts communicate, data contracts, external services
- [Deployment Guide](./deployment-guide.md) — Docker, nginx, CI/CD, production architecture, ops scripts
- [Project Parts Metadata](./project-parts.json) — Machine-readable project structure

### Backend
- [Architecture — Backend](./architecture-backend.md) — Laravel architecture, auth, RBAC, services, events, admin panel
- [API Contracts — Backend](./api-contracts-backend.md) — All API endpoints, request/response formats, rate limits
- [Data Models — Backend](./data-models-backend.md) — Database schema, relationships, entity diagram
- [Development Guide — Backend](./development-guide-backend.md) — Setup, testing, commands, conventions

### Mobile App
- [Architecture — Mobile App](./architecture-mobile-app.md) — Flutter architecture, BLoC pattern, auth flow, offline handling
- [Component Inventory — Mobile App](./component-inventory-mobile-app.md) — All pages, widgets, cubits, dialogs
- [Development Guide — Mobile App](./development-guide-mobile-app.md) — Setup, testing, build, conventions

### Website
- [Architecture — Website](./architecture-website.md) — Static site architecture, build process, pages
- [Development Guide — Website](./development-guide-website.md) — Setup, build, adding pages

---

## Existing Documentation

### Operational Guides
- [CRM Playbook](./CRM_PLAYBOOK.md) — Customer service SOPs and training
- [Deployment Guide (existing)](./deployment.md) — Original deployment documentation
- [Platform Admin](./PLATFORM_ADMIN.md) — Admin panel documentation
- [Mobile App (existing)](./MOBILE_APP.md) — Original mobile app documentation
- [Website (existing)](./mitabl_WEBSITE.md) — Original website documentation

### Setup & Configuration
- [Firebase Setup](./FIREBASE_SETUP.md) — Firebase configuration guide
- [APK Builder](./APK_BUILDER.md) — Android APK build instructions
- [Environment & Secrets](./ENV_VARIABLES_SECRETS_ROTATION.md) — Secrets management and rotation
- [Config Requirements](./config_requirement.md) — Configuration requirements

### Planning & History
- [Planned Improvements](./Planned%20Improvements.md) — Roadmap items

### Root-Level Docs
- [README.md](../README.md) — Comprehensive project overview
- [TEST_USER.md](../TEST_USER.md) — Test user credentials

---

## Getting Started

### For New Developers
1. Read [Project Overview](./project-overview.md) for platform context
2. Read the architecture doc for your area ([backend](./architecture-backend.md), [mobile](./architecture-mobile-app.md), [website](./architecture-website.md))
3. Follow the relevant [development guide](./development-guide-backend.md) to set up locally
4. Review [Integration Architecture](./integration-architecture.md) if working across parts

### For AI-Assisted Development
1. Start with this `index.md` as the entry point
2. Reference [API Contracts](./api-contracts-backend.md) for endpoint details
3. Reference [Data Models](./data-models-backend.md) for schema understanding
4. Reference [Component Inventory](./component-inventory-mobile-app.md) for mobile UI patterns
5. For full-stack features: read both part architectures + [Integration Architecture](./integration-architecture.md)

### For Brownfield PRD
When planning new features, provide this index as input to the PRD workflow:
- **UI-only features:** Reference `architecture-mobile-app.md` + `component-inventory-mobile-app.md`
- **API-only features:** Reference `architecture-backend.md` + `api-contracts-backend.md`
- **Full-stack features:** Reference all architecture docs + `integration-architecture.md`
