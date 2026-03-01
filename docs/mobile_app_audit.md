# Mobile App Performance & UX Deep-Dive Audit

## Scope and approach

This review focused on runtime hotspots and user-facing friction in the Flutter app under `mobile-app/lib`, with emphasis on:

- Network/data layer behavior (request lifecycle, error handling, token handling).
- Screen-level rendering patterns that can affect jank and battery usage.
- State-management patterns that can cause redundant work.
- UX reliability and interaction feedback quality.

## Key findings (prioritized)

### 1) **Network clients are repeatedly created without clear lifecycle management** (High impact)

**Evidence:**

- `AuthenticationRepository` creates fresh `http.Client()` instances in many methods (`logIn`, `forgot`, `logOutApi`, `signUp`, `otpVerify`) but does not close them. Multipart requests are also manually composed repeatedly.【F:lib/repos/authentication_repository.dart†L45-L61】【F:lib/repos/authentication_repository.dart†L66-L89】【F:lib/repos/authentication_repository.dart†L91-L108】
- `UserRepository` repeats the same pattern for profile/dashboard requests (`getCookProfile`, `getDashboardData`, `getFoodieProfile`, `deleteImage`) and similarly leaves client lifecycle unmanaged.【F:lib/repos/user_repository.dart†L80-L99】【F:lib/repos/user_repository.dart†L102-L123】【F:lib/repos/user_repository.dart†L129-L150】

**Why this matters:**

- Repeated transient clients increase connection setup overhead and reduce opportunities for socket reuse.
- Lack of a shared request pipeline makes global timeout/retry/telemetry strategies hard.

**Recommendation:**

- Introduce a shared API client/service (single `http.Client` injected via repository constructors).
- Centralize headers, token injection, timeout handling, and common response parsing.
- Ensure repositories expose typed results (e.g., `Either<Failure, T>` or sealed response types), not `dynamic`.

---

### 2) **Sensitive runtime data is logged in production paths** (High impact, security + UX trust)

**Evidence:**

- Access tokens and API responses are printed in repositories and cubits (e.g., `print(await _accessToken())`, `print(userModel!.data!.accessToken)`, request maps and response payloads).【F:lib/repos/user_repository.dart†L84-L96】【F:lib/pages/home/cubit/home_cubit.dart†L112-L136】【F:lib/pages/home/cubit/home_cubit.dart†L154-L181】

**Why this matters:**

- Tokens and PII in logs can leak through debug tooling, crash reporting, or shared device logs.
- Verbose synchronous logging can degrade perceived responsiveness on lower-end devices.

**Recommendation:**

- Remove raw `print` calls from business logic.
- Add structured logging with severity levels and redact secrets.
- Gate debug diagnostics behind build mode checks.

---

### 3) **Home feed loads rely on hardcoded location and trigger redundant request work** (High impact)

**Evidence:**

- HomeCubit constructor triggers three API calls immediately (`onRecommendedRestaurants`, `onTopratedRestaurants`, `onNearByRestaurants`).【F:lib/pages/home/cubit/home_cubit.dart†L26-L31】
- Location parameters are hardcoded (`lat=30.6754`, `lon=76.7405`) in both top-rated and nearby queries, reducing relevance for all users outside that area.【F:lib/pages/home/cubit/home_cubit.dart†L117-L121】【F:lib/pages/home/cubit/home_cubit.dart†L159-L163】
- `onApplyFilter` invokes all three API calls again without cancellation/debounce, which can stack requests when users adjust filters quickly.【F:lib/pages/home/cubit/home_cubit.dart†L202-L209】

**Why this matters:**

- Users see recommendations unrelated to their actual location.
- Multiple uncancelled requests increase latency, battery use, and risk stale UI state races.

**Recommendation:**

- Use device geolocation (with explicit permission UX and fallback state).
- Debounce filter changes and cancel in-flight calls when new filter input arrives.
- Aggregate feed requests where possible or load incrementally with visible skeleton states.

---

### 4) **Global UI side effects are executed inside `build()`** (Medium impact)

**Evidence:**

- `SystemChrome.setSystemUIOverlayStyle` is called on every `HomePage.build()`.【F:lib/pages/home/view/home_page.dart†L62-L64】

**Why this matters:**

- Re-running platform channel operations every rebuild can cause unnecessary overhead.

**Recommendation:**

- Move one-time system UI configuration to `initState` (or app-level theme/system overlays).

---

### 5) **Large scrollable home layout renders all sections in a single `SingleChildScrollView`** (Medium impact)

**Evidence:**

- Home page composes multiple heavy sections (`CarouselSlider`, top-rated list, nearby list) in one `SingleChildScrollView` + `Column`.【F:lib/pages/home/view/home_page.dart†L72-L185】

**Why this matters:**

- This pattern encourages eager build/layout of all sections and can hurt first meaningful paint.

**Recommendation:**

- Move to a sliver-based layout (`CustomScrollView` + `SliverList`/`SliverToBoxAdapter`) with lazy section construction.
- Consider paginated/virtualized cards for long restaurant lists.

---

### 6) **Search/location input in home header is currently non-functional UX chrome** (Medium impact)

**Evidence:**

- Header `TextFormField` uses static hint (`'492 Morissette Roads'`) with empty `onChanged`, giving the appearance of search/location interaction but no behavior.【F:lib/pages/home/view/home_page.dart†L214-L241】

**Why this matters:**

- Interactive-looking but inert controls reduce user confidence and discoverability.

**Recommendation:**

- Either wire it to actual search/location update behavior (with debounced query and loading feedback) or replace with a non-editable location chip + clear CTA.

---

### 7) **Error handling and return types reduce predictability for both UX and maintainability** (Medium impact)

**Evidence:**

- Many repository methods return `dynamic?` and return the same response for both success and failure paths; exceptions are often swallowed with `print` only.【F:lib/repos/authentication_repository.dart†L53-L64】【F:lib/repos/authentication_repository.dart†L133-L142】【F:lib/repos/user_repository.dart†L51-L58】

**Why this matters:**

- UI layers struggle to distinguish retryable vs validation vs auth failures.
- Inconsistent error mapping tends to produce generic “Something went wrong” UX.

**Recommendation:**

- Adopt typed domain failures and explicit status mapping (e.g., unauthorized, timeout, validation).
- Surface actionable error copy and retry affordances per context.

---

### 8) **Potential crash path via unchecked null route arguments in settings** (Medium impact, UX reliability)

**Evidence:**

- `widget.routeArguments!.id` is force-unwrapped in settings item tap handling.【F:lib/pages_cook/settings_page/view/settings_page_cook.dart†L223-L231】

**Why this matters:**

- Any misrouted navigation or null arguments can produce a runtime crash.

**Recommendation:**

- Guard with null-safe branching and default navigation behavior.
- Add route-level assertions/tests to validate required arguments.

# 
