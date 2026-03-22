# mitabl Website — Architecture Document

**Generated:** 2026-03-14 | **Scan Level:** Exhaustive | **Part:** website | **Type:** Static Marketing Site

---

## Executive Summary

The mitabl website is a static marketing site built with a custom zero-dependency Node.js static site generator. It serves 6 pages (home, about, FAQ, contact, privacy policy, terms) using Bootstrap 4 for styling. The contact page submits support tickets to the backend API. In production, the website's built files are bundled into the backend Docker container and served by the same nginx instance.

---

## Technology Stack

| Category | Technology | Version |
|----------|-----------|---------|
| Build Tool | Custom Node.js SSG | - |
| CSS Framework | Bootstrap | 4.6.1 |
| JS Libraries | jQuery + Popper.js | 3.6.0 / 1.16.1 |
| Fonts | Adobe Typekit (ITC Avant Garde Gothic Pro) | - |
| Serving | Nginx | 1.27-alpine |
| Dependencies | None (zero npm dependencies) | - |

---

## Build Process

The `build-static-site.js` script:
1. Imports shared templates (header, footer, modal) from `src/templates.js`
2. Iterates a 6-page manifest with per-page config flags
3. For each page: reads HTML partial → wraps with header/footer → conditionally inserts "Coming Soon" modal
4. Writes assembled HTML to `public/`

**Build command:** `npm run build` (also used as test)

---

## Pages

| Page | Slug | Key Content |
|------|------|------------|
| **Home** | index | 3-slide carousel, Foodie/Micook/Partner feature sections |
| **About** | about | Company description, mission/vision, values |
| **FAQ** | faq | 24 questions in 3 sections (General, Foodies, Cooks) |
| **Contact** | contact | AJAX form → `POST /api/support/ticket` with honeypot spam detection |
| **Privacy Policy** | privacy-policy | Full privacy policy (Australian law) |
| **Terms** | terms | Full T&C (ABN 40 658 981 607, NSW jurisdiction) |

---

## Integration with Backend

- **Contact form** submits to `/api/support/ticket` via AJAX POST
- Client-side duplicate prevention: 10-min localStorage hash guard
- Honeypot field (`website`) for spam detection
- In production: website files copied into backend container during Docker build

---

## Deployment Model

- **Dev:** Separate nginx container on port 8080, reverse-proxies API calls to backend:8000
- **Production:** `COPY website/public/ /app/public/` in `Dockerfile.backend.unified` — served by backend container's nginx on port 8000
