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

## Route ownership and boundaries

Same-domain routing is split by path prefix:

- Website (`website/`) serves public pages only (`/`, `/about`, `/faq`, `/privacy-policy`, `/terms`).
- Backend (`backend/`) serves API traffic at `/api/*`.
- Admin (`ops-admin`) is served at `/admin` on the same domain.

## Operational references

- Cutover plan and operational expectations: [`docs/website-stateless-cutover-plan.md`](../docs/website-stateless-cutover-plan.md)
- Ingress policy/source of routing truth: [`deploy/nginx/mitabl.phase0.conf`](../deploy/nginx/mitabl.phase0.conf)
