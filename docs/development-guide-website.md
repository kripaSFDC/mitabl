# mitabl Website — Development Guide

**Generated:** 2026-03-14 | **Scan Level:** Exhaustive | **Part:** website

---

## Prerequisites

- Node.js (any recent version — uses only core modules)

---

## Local Setup

```bash
cd website
npm install    # No dependencies, but initializes package.json
npm run build  # Generates HTML files from partials
```

The build outputs assembled HTML files to `public/`.

---

## Development with Docker

```bash
cd website
docker build -t mitabl-website .
docker run -p 8080:8080 mitabl-website
```

For integrated development with the backend, use the root docker-compose.

---

## Project Structure

```
website/
├── build-static-site.js      # SSG build script
├── package.json               # Build scripts (zero dependencies)
├── Dockerfile                 # Nginx dev container
├── nginx.conf                 # Dev reverse proxy config
├── src/
│   ├── templates.js           # Shared header/footer/modal
│   └── pages/                 # HTML page partials
│       ├── index.html         # Home page
│       ├── about.html         # About page
│       ├── faq.html           # FAQ (24 questions)
│       ├── contact.html       # Contact form (→ /api/support/ticket)
│       ├── privacy-policy.html
│       └── terms.html
└── public/
    ├── frontend/
    │   ├── css/               # Bootstrap + custom styles
    │   └── images/            # Marketing images
    ├── favicon.ico
    └── robots.txt
```

---

## Adding a New Page

1. Create HTML partial in `src/pages/newpage.html`
2. Add entry to pages manifest in `build-static-site.js`:
   ```js
   { slug: 'newpage', showModal: false, showStoreBadges: false }
   ```
3. Run `npm run build`
4. Add navigation link in `src/templates.js` header section
