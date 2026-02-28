# Laravel 8 -> 12 Upgrade Plan (mitabl backend)

## Decision
- Target: Laravel 12 (not 11).
- Reason: all project-critical packages now have Laravel 12 compatible releases; no hard package blocker remains after replacing deprecated CORS package.

## Codebase Analysis Summary
- Current app style is Laravel 8 skeleton (`bootstrap/app.php`, `Http\Kernel`, `RouteServiceProvider`).
- This structure is still valid for upgraded projects; no forced migration to the Laravel 11+ new skeleton is required.
- Main blockers were dependency-level:
  - `fruitcake/laravel-cors` only supports Laravel `^6|^7|^8|^9`.
  - `facade/ignition` is Laravel 7/8 era.
- High-risk app integrations to verify after dependency install:
  - `tymon/jwt-auth` auth guard and middleware (`auth:api`, `jwt.verify`).
  - Horizon queue worker dashboard.
  - Swagger generation (`l5-swagger`).
  - Password reset flow (custom `password_resets` table still configured and should remain valid).

## Compatibility Matrix (selected)
- `laravel/framework`: `^12.1`
- `laravel/horizon`: supports `^9|^10|^11|^12|^13`
- `laravel/sanctum`: v4 supports `^11|^12|^13`
- `darkaonline/l5-swagger`: v10 supports Laravel `^11.44 || ^12.1`
- `owen-it/laravel-auditing`: v14 supports `^11|^12`
- `overtrue/laravel-favorite`: v5 supports `^9|^10|^11|^12`
- `tymon/jwt-auth`: v2.2 supports `^9|^10|^11|^12`

## Implemented Changes
1. Dependency upgrades in `composer.json`
- Upgraded framework + ecosystem packages to Laravel 12 compatible ranges.
- Removed `fruitcake/laravel-cors`.
- Removed `facade/ignition`.
- Upgraded test/dev toolchain to modern versions (`phpunit ^11.5`, `collision ^8.6`, etc.).
- Set `minimum-stability` to `stable`.

2. Middleware migration
- Replaced CORS middleware class in `app/Http/Kernel.php`:
  - From `\Fruitcake\Cors\HandleCors::class`
  - To `\Illuminate\Http\Middleware\HandleCors::class`
- Updated JWT middleware alias for `tymon/jwt-auth` v2:
  - From `Tymon\JWTAuth\Middleware\GetUserFromToken::class`
  - To `Tymon\JWTAuth\Middleware\Authenticate::class`

3. PHPUnit 11 format updates
- Updated `phpunit.xml`:
  - New schema location format.
  - Replaced legacy `<coverage ...>` with `<source>`.

4. Route namespace modernization
- Removed legacy namespace chaining from `RouteServiceProvider`.
- Removed legacy `'namespace' => 'Api'` key from `routes/api.php` v1 group.

## Remaining Execution Steps (environment-dependent)
1. Install/update dependencies:
```bash
composer update
```
2. If conflict appears:
```bash
composer why-not laravel/framework ^12.1
```
3. Clear caches:
```bash
php artisan optimize:clear
```
4. Run tests:
```bash
php artisan test
```
5. Verify critical runtime paths:
- login/logout + JWT token validation
- queue worker + Horizon UI
- Swagger docs generation endpoint
- password reset request + reset completion

## Known Constraints During This Session
- Host shell lacked `php` and `composer`, so dependency resolution could not be executed locally.
- Docker CLI existed but daemon was unavailable, so containerized composer install could not run.
