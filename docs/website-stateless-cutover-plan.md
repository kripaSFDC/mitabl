# Website Stateless Cutover & Repo Simplification Plan

## Deep analysis summary

### Legacy arrangement findings

1. The `website/` Laravel app previously had its own Eloquent model layer and migrations, effectively duplicating backend domain entities such as `User`, `Mikitchn`, `Order`, `Review`, and related lookup tables.
2. The public website also exposed integration proxy APIs (`/api/support/ticket`) to forward intake requests into backend services.
3. Deployment topology contained a dedicated `website-db-migrate` workload and website DB environment variables (`DB_*`, `BACKEND_API_BASE_URL`) even though website runtime requirements can be purely static.

### Entity cross-validation (duplication check)

The duplicate entity surface between `website/` and `backend/` included these model names:

- `CookingStyles`
- `Favorite`
- `Foods`
- `Mikitchn`
- `Order`
- `OrderData`
- `PromoCode`
- `Review`
- `Role`
- `SpecialDiet`
- `User`
- `verifyOtp`

This confirms backend should remain the only persistence authority.

## What is implemented in this change set

1. Website is now marketing-only + stateless:
   - Website DB models and migrations removed.
   - Website API intake proxy controller removed.
   - Website API routes replaced with a fallback 404 JSON response.
2. Support ticket intake removed from public website integration path:
   - Registration/contact frontend forms removed from `website/`.
   - Public intake proxy endpoints removed from `website/routes/api.php`.
3. Backend public intake routes disabled:
   - `POST /api/support/ticket`
   - `GET /api/support/ticket/{id}`
   - `POST /api/support/ticket/{id}/reply`
4. System health route audit updated to assert legacy public intake routes are disabled.
5. Deployment simplified:
   - `website-db-migrate` service removed from compose files.
   - Marketing-web environment templates no longer include website DB or backend proxy variables.

## Route ownership and ingress boundaries

At runtime, route ownership is intentionally split on the same domain:

- Website (`website/`) serves public pages only.
- Backend (`backend/`) serves `/api/*`.
- Admin (`ops-admin`) is served at `/admin`.

Ingress routing source of truth: [`deploy/nginx/mitabl.phase0.conf`](../deploy/nginx/mitabl.phase0.conf).
Website developer docs: [`website/README.md`](../website/README.md).

## Target structure alignment

The repository is now moving toward:

- One backend (`backend/`) for all persistence and admin APIs.
- One frontend (`website/`) for public marketing pages.
- One mobile app (`mobile-app/`).

A future phase can consolidate admin blade assets and shared frontend design tokens into a dedicated UI package if desired, but there is no longer duplicated persistence in the website app.
