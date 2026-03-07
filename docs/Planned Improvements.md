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
   
   

---

## 3- Backend/API

1. Currently there is no security/verification on user registration endpoint i.e. anyone can hit this endpoint and create as many cooks/foodies as one wants! There is no check if cook or foodi is genuinely created by mitabl app!!!

2. **No real GPS integration: users type coordinates manually**home_cubit.dart:100-115 and home_page.dart: location is a text field accepting `"latitude, longitude"`. There is no call to `geolocator` or any platform location API. Users literally have to know and type their GPS coordinates.

3. Hardcoded discount rules and amounts**`OrderService` has `if ($this->completedOrderCountForUser($user->id) < 5)` and `$order->discounted_amount = 50` ,  magic numbers with no config, feature flag, or admin control. The GST rate `10` is also hardcoded in at least two places (`checkDiscountedUser`, `DiscoveryController::show`).

4. Attachment malware scanning pipeline and enforced attachment type/size policy are still not end-to-end wired (schema exists, but no upload/scanning workflow in these modules).

5. Styling and look and feel of Platform admin & CRM pages (all filament pages) is matching with the public website


