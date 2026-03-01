Marketing Website (Static)
==========================

This directory now contains a static frontend for the mitabl marketing site.

## Local preview

From the repository root:

```bash
docker compose up --build website
```

Then open `http://localhost:8080`.

## Routes

- `/`
- `/about`
- `/faq`
- `/privacy-policy`
- `/terms`
- `/health`

## Notes

- No Laravel runtime is required for `website/`.
- No PHP/composer setup is required.
- Static assets are served from `website/public/` via nginx.
