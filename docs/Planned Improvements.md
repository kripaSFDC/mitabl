# mitable - Planned Improvements

## 1- Website

1. **Template consolidation**
   
   * Extract repeated header/footer/scripts into a static-site templating pipeline to reduce drift.

2. **Accessibility hardening**
   
   * Add semantic landmarks, richer alt text where relevant, and explicit focus/keyboard states for all interactive elements.

3. **Observability for contact flows**
   
   * Replace `mailto` form with API-backed contact submission, anti-spam controls, and audit-ready delivery tracking.

4. **Performance and cache policy**
   
   * Add asset fingerprinting and long-lived immutable cache headers for static media/CSS.
     
     

---

## 2- Mobile App

1. Security improvements

2. UI/UX improvements

3. **Current State (Today)**
   
   * There is **no client-side Google Maps integration** (no google_maps_flutter, no map widget, no Places autocomplete, no map screen) in the mobile app.
   * Google Maps is only present as a **backend reverse-geocoding helper trait** in [GoogleAddress.php](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-26.5304.20706-win32-x64/webview/), but it appears effectively inactive in current user flows.
   * **No real GPS integration: users type coordinates manually**home_cubit.dart:100-115 and home_page.dart: location is a text field accepting `"latitude, longitude"`. There is no call to `geolocator` or any platform location API. Users literally have to know and type their GPS coordinates.
   * Geolocation in app is handled by geolocator in mobile home feed:
     * gets device location once on home load via [Geolocator.getCurrentPosition](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-26.5304.20706-win32-x64/webview/)
     * stores lat/lon in state and pre-fills text input as "lat, lon" ([home_cubit.dart](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-26.5304.20706-win32-x64/webview/), [home_page.dart](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-26.5304.20706-win32-x64/webview/))
     * sends lat/lon/max_distance to discovery endpoints for nearby/top-rated ([home_cubit.dart](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-26.5304.20706-win32-x64/webview/), [home_repository.dart](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-26.5304.20706-win32-x64/webview/))
     * backend computes distance using Haversine-style SQL in [Mikitchn::closest](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-26.5304.20706-win32-x64/webview/) via discovery service ([DiscoveryService.php](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-26.5304.20706-win32-x64/webview/))

4. 

---

## 3- Backend/API

1. Currently there is no security/verification on user registration endpoint i.e. anyone can hit this endpoint and create as many cooks/foodies as one wants! There is no check if cook or foodi is genuinely created by mitabl app!!!

2. Hardcoded discount rules and amounts**`OrderService` has `if ($this->completedOrderCountForUser($user->id) < 5)` and `$order->discounted_amount = 50` ,  magic numbers with no config, feature flag, or admin control. The GST rate `10` is also hardcoded in at least two places (`checkDiscountedUser`, `DiscoveryController::show`).

3. Attachment malware scanning pipeline and enforced attachment type/size policy are still not end-to-end wired (schema exists, but no upload/scanning workflow in these modules).

4. Styling and look and feel of Platform admin & CRM pages (all filament pages) is matching with the public website
