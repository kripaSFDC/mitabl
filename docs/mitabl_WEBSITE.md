# mitabl Public Website — Current State Review

## 1) Purpose and product boundary

The `website/` project is the public marketing surface for mitabl. It is intentionally non-transactional and is used for:

- Brand and product narrative.
- Public FAQ context for platform boundaries.
- Contact pathways.
- Legal documents (Terms + Privacy Policy).

The website does **not** process ordering, payments, identity, or admin operations directly; those responsibilities stay in backend and mobile/admin surfaces. The FAQ content explicitly reflects this split. 

---

## 2) Architecture and build model (updated)

### Source-of-truth vs generated files

The site now uses a lightweight Node-based static composition flow:

- Page body source content lives in `website/src/pages/*.html`.
- Shared shell/layout is defined in `website/src/templates.js` (`header`, `modal`, `footer`).
- `website/build-static-site.js` composes these into final static pages in `website/public/*.html`.

This means `website/public/*.html` is build output, while ongoing page edits should generally happen in `website/src/pages/*` and shared chrome changes in `website/src/templates.js`.

### Build and test commands

From repo root:

```bash
npm --prefix website run build
npm --prefix website run test
```

Current behavior:

- `build` runs `node build-static-site.js` and regenerates all public pages.
- `test` currently aliases to `npm run build` (packaging consistency check, no separate unit/integration test suite).

### Runtime delivery

- Public files are served as static assets from `website/public`.
- nginx extensionless routing is configured with:
  - `try_files $uri $uri.html $uri/ $uri/index.html =404;`
- Health endpoint:
  - `GET /health` returns `200 ok` plain text.

Production note:

- Contabo production now uses a unified backend container image (`deploy/Dockerfile.backend.unified`) that copies `website/public` into backend `public/` and serves all routes via backend on `:8000`.
- The standalone `website` container model remains useful for isolated website development/testing, but is not the canonical production ingress path anymore.

Containerization remains minimal:

- Base image: `nginx:1.27-alpine`.
- Copies `website/public/` to `/usr/share/nginx/html`.
- Exposes port `8080`.

---

## 3) Current page inventory

The build currently emits six top-level routes:

1. `/` → `index.html`
2. `/about` → `about.html`
3. `/faq` → `faq.html`
4. `/contact` → `contact.html`
5. `/privacy-policy` → `privacy-policy.html`
6. `/terms` → `terms.html`

All routes are declared in the `pages` array in `website/build-static-site.js` and use page-specific metadata (`title`, modal/store-badge toggles).

---

## 4) Shared layout behavior and recent fixes

## Header/nav

Shared header/nav is generated from `templates.js` and includes:

- Skip link (`Skip to main content`) for keyboard/screen-reader access.
- Responsive Bootstrap navbar with explicit ARIA attributes.
- Primary nav links: HOME, ABOUT, FAQ, CONTACT.

## Footer variants

Footer is also centralized in `templates.js` and now supports two behavior modes:

- **Marketing pages** (`index`, `about`, `faq`): show app-store badge CTAs that open the “Coming Soon” modal.
- **Contact/legal pages** (`contact`, `privacy-policy`, `terms`): show social links in the footer instead of store badges.

Common footer links include `Terms`, `Privacy Policy`, and `Contact`, plus copyright text (`© 2026 mitabl All rights reserved.`).

## Modal and client-side scripts

Interactive behavior is intentionally small and currently includes:

- Bootstrap modal for app-store “Coming Soon” messaging.
- jQuery-based nav active-state highlighting by path segment.
- Click handler that prevents default navigation for placeholder `href="#"` modal triggers.

Scripts are loaded from CDNs (`jQuery 3.6.0`, `Popper 1.16.1`, `Bootstrap 4.6.1 bundle`).

## Accessibility-oriented improvements now present

Recent templating updates include:

- Semantic landmarks (`header`, `main`, `footer`) and banner/contentinfo roles.
- Explicit `alt` text across key imagery/icons.
- Better ARIA labeling on nav controls, home links, modal title binding, and external footer links.

---

## 5) Content review by page (current)

### Home (`src/pages/index.html`)

- Hero + audience-oriented value proposition.
- Sections for Foodies, miCooks, and Partners.
- CTA store badges route through the shared modal.

### About (`src/pages/about.html`)

- Mission/vision narrative for local food ecosystem positioning.
- “Real Local Connections” list and platform statement.

### FAQ (`src/pages/faq.html`)

- Repository-aware operational FAQ, including:
  - website/backend/admin boundary definitions,
  - ingress split expectations,
  - support/CRM lifecycle language,
  - security and privacy framing,
  - high-level account/order/payment capability references.

### FAQ canonical-source policy

- **Canonical FAQ source = website route `https://mitabl.com/faq`**
- FAQ edits must be made in the website FAQ source files (`website/src/pages/faq.html`, then rebuilt to `website/public/faq.html`).
- Mobile clients must not duplicate FAQ content as static in-app text; they should load the canonical website FAQ URL in WebView.

### Contact (`src/pages/contact.html`)

- Contact narrative for Foodies, miCooks, and partners.
- Direct email link (`mailto:admin@mitabl.com`).
- Social links (Instagram, Facebook, LinkedIn, X).
- Contact form posts via `mailto:` with plain-text encoding.

### Terms + Privacy (`src/pages/terms.html`, `src/pages/privacy-policy.html`)

- Long-form legal and privacy content rendered within shared site shell.

---

## 6) Operational considerations and caveats

- `mailto:` forms depend on a configured local mail client and are not suitable for reliable server-side delivery tracking, anti-spam controls, or structured CRM automation.
- Because public pages are generated from source templates/pages, manual edits to `website/public/*.html` can be overwritten by the build script.
- Current JavaScript dependencies are CDN-hosted; availability and CSP policy should be considered if moving to stricter enterprise controls.

---

## 7) Practical maintenance guidance

When updating website content/features:

1. Edit page bodies in `website/src/pages/*`.
2. Edit shared nav/footer/modal/script shell in `website/src/templates.js`.
3. Run `npm --prefix website run build` to regenerate `website/public/*`.
4. Verify extensionless local routes (e.g., `/about`, `/faq`, `/contact`) under static hosting/nginx.
5. For FAQ claims about backend/admin behavior, keep statements mapped to live repo behavior and avoid unsupported operational promises.

This document has been refreshed to align with the current generated-static architecture and recent website fixes (templating centralization, accessibility improvements, contact-page/ footer behavior updates, and current nginx delivery model).
