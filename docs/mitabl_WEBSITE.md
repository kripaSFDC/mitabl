# Overview of mitabl Public Website

## Purpose and product scope

The `website/` project is a static, marketing-focused public surface for mitabl. It is intentionally non-transactional and designed to communicate brand positioning, product context, legal terms, privacy policy, and contact pathways for users and partners. The site ships as pre-rendered HTML/CSS assets served by nginx and does not require an application runtime, database, or API dependency to render pages.

The `website/` project is a **static site** that serves public marketing pages only.

* **No runtime JavaScript build chain is required** to run or deploy this site.
* **No local database or API dependency is required** for website pages to render.
  
  

### Runtime architecture and delivery model

* All public pages are static HTML files under `website/public`.
* Shared styling is provided by local CSS (`/frontend/css/style.css`) and Bootstrap v4 CSS (`/frontend/css/bootstrap.min.css`).
* Interactive behaviors are intentionally lightweight and limited to:
  * Bootstrap modal behavior for “Coming Soon” app-store links.
  * jQuery-based navigation highlighting for active menu states.

#### Build

From the repository root:

```
npm --prefix website run build
```



Current behavior: this command validates static-site packaging and performs no application-server or database build steps.

#### Serve locally

Use any static file server pointed at `website/public`.

Example with Python:

```
cd website/public
python3 -m http.server 8080


Then open `http://localhost:8080`.
```



---

 

### Containerization and serving

- `website/Dockerfile` builds a minimal nginx image and copies all static assets into `/usr/share/nginx/html`.
- `website/nginx.conf` serves files on port `8080` and resolves extensionless routes using `try_files $uri $uri.html $uri/ $uri/index.html =404;`.
- A dedicated `/health` endpoint returns static plain text (`ok`) for liveness checks.

### Build/test scripts

- `website/package.json` intentionally includes no compile pipeline. `build` and `test` scripts are informational no-op commands to preserve CI compatibility for static packaging.

## 3) Content model and page inventory

The site now includes six primary public pages:

1. `/` (`index.html`) — home/hero marketing narrative and product introduction.
2. `/about` (`about.html`) — mission, vision, and platform-positioning narrative.
3. `/faq` (`faq.html`) — operationally-oriented FAQ spanning product boundaries and support model.
4. `/contact` (`contact.html`) — contact channels, social links, and email form.
5. `/terms` (`terms.html`) — legal terms and conditions.
6. `/privacy-policy` (`privacy-policy.html`) — privacy policy and data-handling statement.

All pages share a common top navigation with links to HOME, ABOUT, FAQ, and CONTACT, plus footer legal navigation that includes CONTACT.

## 4) Detailed code-file review (`website/*`)

This section captures an explicit review of each code/config/document file in `website/`.

### Top-level files

#### `website/README.md`

- Documents the static-site philosophy and boundaries.
- Defines local serving model (`python3 -m http.server 8080`) and route ownership split vs backend/admin surfaces.
- Notes content governance for public claims (FAQ edits should map to repo truths).

#### `website/package.json`

- Package metadata for the website artifact.
- `build` and `test` are intentionally no-op shell echoes, signaling no JS/SPA build chain.

#### `website/Dockerfile`

- Uses `nginx:1.27-alpine`.
- Copies `nginx.conf` and all `public/` assets.
- Exposes `8080`; launches nginx foreground process.

#### `website/nginx.conf`

- Static server configuration with extensionless route support.
- Health route at `/health` for monitoring.
- Correctly avoids unnecessary app-proxy complexity for this static surface.

### Public root files

#### `website/public/index.html`

- Primary hero carousel and top-level product value proposition.
- Uses a shared nav/footer pattern and “Coming Soon” modal for app-store CTAs.
- Includes concise customer/cook/partner-oriented messaging blocks.

#### `website/public/about.html`

- Brand and mission narrative with supporting visual sections.
- Includes mission/vision content blocks and shared layout primitives.

#### `website/public/faq.html`

- Comprehensive platform FAQ with high-level operational language.
- Clarifies website/backend/admin boundaries and support process context.

#### `website/public/contact.html`

- Dedicated contact destination with:
  - Direct support email (`mitablinfo@gmail.com`).
  - Public social links for mitabl channels.
  - Email form using `mailto:mitablinfo@gmail.com` to initiate message composition via user mail client.
- Maintains site-wide nav/footer consistency.

#### `website/public/terms.html`

- Long-form legal terms and conditions content.
- Uses consistent header/footer shell and legal-content formatting block.

#### `website/public/privacy-policy.html`

- Long-form privacy policy with collection/use/disclosure/security headings.
- Uses shared legal-content rendering style.

#### `website/public/robots.txt`

- Allows crawling (`User-agent: *`, no disallow restrictions).

### Front-end styling files

#### `website/public/frontend/css/style.css`

- Primary custom stylesheet governing:
  - Header/nav styles and active-state treatment.
  - Hero/carousel sections.
  - About, privacy/legal, modal, footer, and responsive mobile rules.
  - Contact-section and form styles (including social-link and submit affordances).
- Contains extensive single-file styling architecture; suitable for static site scale but should be modularized if page count grows.

#### `website/public/frontend/css/bootstrap.min.css`

- Third-party minified Bootstrap distribution (vendor dependency).
- Not treated as source-of-truth business logic; should be version-pinned and replaced only through controlled upgrades.

### Public binary/media assets (review summary)

- `website/public/favicon.ico`
- `website/public/frontend/background.jpg`
- `website/public/frontend/logo.png`
- `website/public/frontend/images/*` (branding, hero, CTA, and iconography)

These files provide brand/media presentation only and contain no executable business logic. They should remain immutable release artifacts, with naming/version control discipline to support cache management.

## 5) Navigation and UX consistency

- Primary navigation is now consistent across all public pages and includes CONTACT in the main menu.
- Footer legal nav includes CONTACT alongside Terms and Privacy links.
- Active-menu highlighting is handled uniformly by shared jQuery snippet logic based on URL path segment matching.

## 6) Contact and communications behavior

The contact experience supports two direct pathways:

1. **Immediate email** via clickable `mailto:mitablinfo@gmail.com` link.
2. **Structured form submission** via HTML form posting to `mailto:mitablinfo@gmail.com`.

Operational note: `mailto` forms depend on client email configuration. For enterprise-grade analytics, spam mitigation, and deliverability observability, a future phase should replace `mailto` with a managed backend endpoint or transactional email provider integration.

## 7) Security, compliance, and operational posture

- Static architecture minimizes attack surface relative to dynamic runtimes.
- nginx health endpoint supports orchestration readiness checks.
- Legal pages (Terms/Privacy) are first-class navigable pages.
- External links in contact/social usage include `rel="noopener noreferrer"` when opening new tabs.
  
  

----
