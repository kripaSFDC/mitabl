# Website (Static Marketing Site)

The `website/` project is a **static site** that serves public marketing pages only.

- **No runtime JavaScript build chain is required** to run or deploy this site.
- **No local database or API dependency is required** for website pages to render.

## Build

From the repository root:

```bash
npm --prefix website run build
```

Current behavior: this command validates static-site packaging and performs no application-server or database build steps.

## Serve locally

Use any static file server pointed at `website/public`.

Example with Python:

```bash
cd website/public
python3 -m http.server 8080
```

Then open `http://localhost:8080`.

## Public asset structure

The static pages under `website/public/*.html` should only reference versioned, checked-in UI assets in:

- `website/public/frontend/images/` for page imagery (branding, hero, and UI-support images).
- `website/public/frontend/css/` for stylesheets.

Expected image set in `website/public/frontend/images/`:

- `app.png`
- `banner.png`
- `cont.png`
- `count.png`
- `google.png`
- `home1.jpg`
- `home2.jpg`
- `home3.jpg`
- `log03.png`
- `logo.png`
- `logo1.png`
- `logo2.png`
- `logo4.png`
- `mission.png`
- `rocket.png`
- `slider-2.jpg`
- `slider-3.jpg`
- `toggle.png`
- `vision.png`

Do **not** store runtime user uploads in `website/public`. Legacy upload directories such as
`website/public/Images/user/` and `website/public/Images/kitchen/` are intentionally removed and
should not be reintroduced.

## Route ownership and boundaries

Same-domain routing is split by path prefix:

- Website (`website/`) serves public pages only (`/`, `/about`, `/faq`, `/privacy-policy`, `/terms`).
- Backend (`backend/`) serves API traffic at `/api/*`.
- Admin (`ops-admin`) is served at `/admin` on the same domain.

## Operational references

- Cutover plan and operational expectations: [`docs/website-stateless-cutover-plan.md`](../docs/website-stateless-cutover-plan.md)
- Ingress policy/source of routing truth: [`deploy/nginx/mitabl.phase0.conf`](../deploy/nginx/mitabl.phase0.conf)


## Internal content review checklist (FAQ and public claims)

Before merging edits to `website/public/faq.html` (or similar public informational pages), verify every non-trivial claim maps to a repository source:

- Confirm platform-level positioning and product boundaries against `README.md`.
- Confirm support/CRM workflow terminology against `docs/crm_playbook_and_training.md`.
- Confirm website stateless and ownership language against `docs/website-stateless-cutover-plan.md`.
- Confirm ingress path boundaries and admin network controls against `deploy/nginx/mitabl.phase0.conf`.
- Confirm backend capability statements using `backend/routes/api.php` at a high level (route groups, public endpoints, and middleware patterns), without documenting unstable implementation minutiae.
- If a claim cannot be mapped to these files, either remove it or add/update the authoritative documentation first.
