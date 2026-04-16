# Commit Conventions

This project follows [Conventional Commits](https://www.conventionalcommits.org/) to keep the git history scannable and automatable.

## Format

```
<type>(<scope>): <short summary>

<optional body>

Co-Authored-By: Paperclip <noreply@paperclip.ing>
```

## Types

| Type         | When to use                                           |
|--------------|-------------------------------------------------------|
| `feat`       | A new feature or user-facing capability               |
| `fix`        | A bug fix                                             |
| `refactor`   | Code change that neither fixes a bug nor adds a feature (cleanup, rename, restructure) |
| `docs`       | Documentation-only changes                            |
| `test`       | Adding or updating tests                              |
| `ci`         | CI/CD pipeline changes (GitHub Actions, Docker, etc.) |
| `chore`      | Dependency bumps, tooling config, other maintenance   |
| `perf`       | Performance improvement                               |
| `style`      | Formatting, whitespace, semicolons (no logic change)  |

## Scope

Optional but encouraged. Use the area of the codebase affected:

- `backend`, `mobile`, `web` for top-level targets
- Specific module names like `orders`, `auth`, `payments`, `discovery`

Examples: `feat(mobile): add dine-in booking flow`, `fix(backend/orders): correct refund calculation`

## Rules

1. **Subject line under 72 characters.**
2. **Use imperative mood** in the subject: "add feature" not "added feature" or "adding feature".
3. **No commented-out code in commits.** Remove dead code before committing. Use `git log` to recover old code if needed.
4. **No debug statements** (`dd()`, `dump()`, `print_r()`, `die()`, `echo` for debugging) in committed code.
5. **Remove unused imports** before committing.
6. **One logical change per commit.** Split unrelated changes into separate commits.
7. **Always include `Co-Authored-By: Paperclip <noreply@paperclip.ing>`** when the commit is produced by an agent.

## Pre-commit Checklist

Before committing, verify:

- [ ] No commented-out code left behind
- [ ] No debug/logging statements meant for local development
- [ ] No unused `use` imports
- [ ] Tests pass (when applicable)
- [ ] Commit message follows the format above
