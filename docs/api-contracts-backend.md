# mitabl Backend — API Contracts

**Generated:** 2026-03-14 | **Scan Level:** Exhaustive | **Part:** backend

---

## Base URL

- **Production:** `https://mitabl.com/api/`
- **Development:** `http://localhost:8000/api/`

## Authentication

- **Method:** JWT Bearer Token
- **Header:** `Authorization: Bearer {token}`
- **Token TTL (prod):** 7 days (10080 minutes)
- **Refresh TTL (prod):** 14 days (20160 minutes)

---

## Health Endpoints

| Method | Path | Auth | Rate Limit | Description |
|--------|------|------|-----------|-------------|
| GET | `/health` | None | api | Plain text "ok" |
| GET | `/health/live` | None | api | JSON: `{"status":"ok","timestamp":"..."}` |
| GET | `/health/startup` | None | api | JSON: `{"status":"ok","app_env":"...","timestamp":"..."}` |
| GET | `/health/ready` | None | api | Full readiness check via SystemHealthService; 503 on failures |

---

## Public Endpoints (No Authentication)

| Method | Path | Controller | Rate Limit | Request Body | Success Response |
|--------|------|-----------|-----------|-------------|-----------------|
| GET | `/app/version` | AppVersionController@show | 60/min | - | `{min_version, latest_version, ios_url, android_url}` |
| POST | `/login` | UserController@login | 10/min | `{email, password}` | `{access_token, token_type, user:{id,name,role,roleId}}` |
| POST | `/token/refresh` | UserController@refreshToken | 30/min | - (Bearer header) | `{access_token, token_type, user:{...}}` |
| POST | `/register` | UserController@register | - | `{first_name, last_name, email, password, role_id, phone, address}` | `{isSuccess, message, data:{id,name,email,role}}` |
| POST | `/verifyOtp` | UserController@verifyOtp | 10/min | `{user_id, otp}` | `{access_token, user:{...}}` |
| POST | `/resendotp` | UserController@resendOtp | 5/min | `{user_id, email}` | `{message}` |
| POST | `/password/reset` | ResetPasswordController | - | `{email}` | `{message}` |
| POST | `/stripe/webhook` | StripeWebhookController | - | Stripe event payload | 200 OK |
| POST | `/support/ticket` | SupportTicketController@store | 4/min per email | `{requester_name, requester_email, subject, description, ?requester_phone, ?category, ?order_id, ?website(honeypot)}` | `{data:{id, ticket_number, status, requester_token}}` |
| GET | `/support/ticket/{id}` | SupportTicketController@show | 30/min | Query: `?token={requester_token}` | `{data:{ticket with messages}}` |
| POST | `/support/ticket/{id}/reply` | SupportTicketController@reply | 12/min | `{message, ?reopen_reason}` + Header: `X-Ticket-Token` | `{data:{message}}` |

---

## Authenticated V2 Endpoints (auth:api + api.user.active)

### Account Management

| Method | Path | Controller | Description |
|--------|------|-----------|-------------|
| GET | `/v2/account/profile` | V2\AccountController@show | Get full user profile (with kitchen if cook) |
| PUT | `/v2/account/profile` | V2\AccountController@update | Update profile fields |
| POST | `/v2/account/switch-role` | V2\AccountController@switchRole | Switch between Foodie (3) and Cook (2) |
| POST | `/v2/account/password/change` | V2\AccountController@changePassword | Change password (requires current_password) |
| POST | `/v2/account/device-token` | V2\AccountController@updateDeviceToken | Update FCM device token |
| POST | `/v2/account/notifications/toggle` | V2\AccountController@notificationsToggle | Toggle push notifications |
| POST | `/v2/account/notification-preferences` | V2\AccountController@updateNotificationPreferences | Update notification settings |
| GET | `/v2/account/mobile-contact` | V2\AccountController@mobileContact | Get mobile contact info |
| GET | `/v2/mob-contact` | UserController@mobileContact | Legacy: user contact details |
| POST | `/v2/logout` | UserController@logout | Invalidate JWT |
| POST | `/v2/editprofile` | UserController@update | Edit profile (legacy multipart) |
| GET | `/v2/getcookingstyles` | UserController@getCookingStyles | Paginated cooking styles (cached 10min) |
| GET | `/v2/getspecialdiets` | UserController@getSpecialDiets | Paginated special diets (cached 10min) |

### Discovery

| Method | Path | Controller | Query Parameters | Description |
|--------|------|-----------|-----------------|-------------|
| GET | `/v2/discovery/filtered` | V2\DiscoveryController@filtered | `latitude, longitude, ?cookingstyle, ?dine_in, ?take_away, ?distance` | Filtered kitchen search |
| GET | `/v2/discovery/nearest` | V2\DiscoveryController@nearest | `latitude, longitude, ?page, ?limit` | Nearest kitchens (Haversine) |
| GET | `/v2/discovery/top-rated` | V2\DiscoveryController@topRated | `latitude, longitude, ?page, ?limit` | Top-rated kitchens |
| GET | `/v2/discovery/recommended` | V2\DiscoveryController@recommended | `latitude, longitude` | Recommended kitchens |
| GET | `/v2/discovery/restaurants/{id}` | V2\DiscoveryController@show | - | Single restaurant detail |

### Payments

| Method | Path | Controller | Request Body | Description |
|--------|------|-----------|-------------|-------------|
| GET | `/v2/payments/cards` | V2\PaymentsController@cards | - | List customer's saved cards |
| POST | `/v2/payments/cards` | V2\PaymentsController@addCard | `{payment_method}` (pm_ prefix required) | Add card to customer |
| POST | `/v2/payments/checkout-session` | V2\PaymentsController@checkoutSession | `{order_id}` | Create Stripe checkout session |
| POST | `/v2/payments/intent` | V2\PaymentsController@createIntent | `{amount, payment_method}` | Create payment intent (foodie only) |
| POST | `/v2/payments/intent/confirm` | V2\PaymentsController@confirmIntent | `{payment_intent_id}` | Confirm payment intent |
| POST | `/v2/payments/vendor-transfer` | V2\PaymentsController@vendorTransfer | - | Always returns 403 (admin-only) |

---

## Restaurant-Role Endpoints (auth:api + restaurant)

| Method | Path | Controller | Description |
|--------|------|-----------|-------------|
| POST | `/v2/mikitchn/store` | MikitchnController@createKitchen | Register new kitchen (multipart: images, timings, certificate) |
| POST | `/v2/mikitchn/editkitchen` | MikitchnController@updateKitchen | Update kitchen details (multipart) |
| POST | `/v2/deleteimage` | MikitchnController@deleteImage | Delete kitchen/food image |
| GET | `/v2/mymenu` | MikitchnController@getMyMenu | Get cook's food menu |
| POST | `/v2/food/add` | FoodsController@createFood | Add food item (multipart) |
| POST | `/v2/food/editfood` | FoodsController@updateFood | Edit food item (multipart) |
| DELETE | `/v2/food/{id}` | FoodsController@destroy | Delete food item |
| POST | `/v2/food/status/{id}` | FoodsController@statusUpdate | Toggle food active/inactive |
| GET | `/v2/getprofile` | UserController@myProfile | Restaurant profile |
| GET | `/v2/kitchenupcomingorders` | OrderController@myUpcomingOrderss | Paginated upcoming orders |
| GET | `/v2/kitchenorderrequest` | OrderController@myRequestedOrders | Paginated order requests |
| GET | `/v2/allorders` | OrderController@allOrders | All orders with filters |
| POST | `/v2/updateorderstatus` | OrderController@statusUpdate | Update order status |
| GET | `/v2/getdashboarddata` | MikitchnController@getDashboardData | Dashboard: earnings, bookings, upcoming |

---

## Customer-Role Endpoint (auth:api + customer)

| Method | Path | Controller | Description |
|--------|------|-----------|-------------|
| GET | `/v2/getcustomerprofile` | UserController@myProfile | Customer profile |

---

## Deprecated/Sunset Endpoints

| Method | Path | Status | Sunset Date | Replacement |
|--------|------|--------|-------------|-------------|
| GET | `/mobcontact` | 410 Gone | Removed | `/v2/mob-contact` |
| GET | `/v1/mob-contact` | 410 Gone | 2026-07-01 | `/v2/mob-contact` |
| GET | `/v1/food/status/{id}` | 405 | - | `POST /v2/food/status/{id}` |
| GET | `/v2/payments/checkout-session` | 405 | - | `POST /v2/payments/checkout-session` |
| GET | `/v2/food/status/{id}` | 405 | - | `POST /v2/food/status/{id}` |

---

## Response Format

### Standard Success Response
```json
{
  "responseCode": 200,
  "isSuccess": true,
  "message": "Success message",
  "data": { ... }
}
```

### Standard Error Response
```json
{
  "responseCode": 422,
  "isError": true,
  "message": "Error description",
  "errors": { "field": ["Validation message"] }
}
```

### API Resource Shapes

#### User Resource
```json
{
  "id": 1, "first_name": "John", "last_name": "Doe",
  "email": "john@example.com", "email_verified": true,
  "role_id": 3, "avatar": "path/to/avatar.jpg",
  "description": "...", "phone": "+61...", "address": "...",
  "role": "Foodie", "notification": 0,
  "is_kitchen_added": true, "is_certificate_approved": true,
  "kitchen": { ... }
}
```

#### Restaurant Resource
```json
{
  "id": 1, "user_id": 1, "name": "Kitchen Name",
  "address": "...", "phone": "...", "no_of_seats": 10,
  "description": "...", "dine_in": 1, "take_away": 1,
  "status": 1, "open": 1, "latitude": -33.8688,
  "longitude": 151.2093, "distance": 2.5,
  "rating_count": 4.5, "orders_count": 50,
  "images": ["path1.jpg", "path2.jpg"],
  "certificate": {"id": 1, "status": "approved", "abn": "...", "abn_gst": "..."},
  "is_favourited": false
}
```

#### Order Resource
```json
{
  "order_id": 1, "order_type_id": "D-1",
  "mikitchn": {"id": 1, "name": "...", "address": "...", "rating_count": 4.5, "images": [...]},
  "customer": {"id": 1, "first_name": "...", "last_name": "...", "phone": "...", "avatar": "..."},
  "date": "2026-03-14", "time_from": "12:00", "time_to": "13:00",
  "persons": 2, "message": "...", "dine_in": 1, "take_away": 0,
  "item_total_price": "45.00", "discounted_amount": "5.00",
  "promo_code": "SAVE10", "taxes": "4.50", "total_price": "44.50",
  "status": 3, "paid": 1, "refund_percentage": 0,
  "items": [{"food": "Pasta", "quantity": 2, "price": "15.00", "total_price": "30.00"}]
}
```

---

## Rate Limiting Summary

| Endpoint Group | Limit | Window |
|---------------|-------|--------|
| Login | 10 requests | 1 minute |
| OTP Verify | 10 requests | 1 minute |
| OTP Resend | 5 requests | 1 minute |
| Token Refresh | 30 requests | 1 minute |
| App Version | 60 requests | 1 minute |
| Support Intake | 4/min per email + 30/hr per IP | - |
| Support Read | 30 requests | 1 minute |
| Support Reply | 12 requests | 1 minute |
| General API | Default throttle | - |
