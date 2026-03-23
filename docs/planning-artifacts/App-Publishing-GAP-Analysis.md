Ready for review
Select text to add comments on the plan
Gap Fix Plan — Publish-Ready App
Context
All 42 screens are built with the Warm Tactile design. This plan fixes all gaps between the design and implementation to make the app publish-ready. Organized into 4 sprints by priority. Each sprint is independently deployable and testable.

Sprint 1: Wire Up Existing APIs (Code-only, no new backend)
These fixes only need mobile-side changes — the backend APIs already exist.

#	Fix	File(s)	What to Do
1.1	Favourites: show images, rating, distance	favourites_page.dart, favourite_cook_card.dart	API already returns images[], rating_count, distance, cock.avatar. Extract and display in cards.
1.2	Payments: wire card list + transaction history	payments_page.dart, visual_credit_card.dart, transaction_row.dart	GET /v2/payments/cards and GET /v2/account/payments/history both exist and return real data. Wire PageView to cards list, ListView to history.
1.3	Search Filters: load cuisines from API	search_filters_page.dart	HomeCubit.onCookingStyle() already fetches from GET /getcookingstyles. Replace 4 hardcoded cuisines with full API list.
1.4	Discovery cook cards: add favourite heart	discovery_cook_card.dart, home_page.dart	FavouritesRepository.toggleFavourite() exists. Add heart icon to cards, wire tap to toggle.
1.5	Cook Dashboard: wire Delay/Mark Ready buttons	home_cook_page.dart	BookingsCubit.updateOrderWorkflowStatus() exists. Wire Delay → status 5, Mark Ready → status 1. Refresh queue after.
1.6	Revenue Analytics: compute from real data	revenue_analytics_page.dart	Dashboard API returns totalEarning, nBookings. Compute avg order. Replace mock top dishes with items from order history (fetch via BookingRepository).
1.7	Order Tracking: poll order status	order_tracking_page.dart	GET /v2/account/orders?status=X exists. Poll every 15s, map status (2→3→5→1) to timeline steps. Not real-time but functional.
1.8	Submit Review: add photo picker	submit_review_page.dart	Add image_picker gallery selection, show preview thumbnails. Photos stored locally for now (backend photo upload API doesn't exist yet).
1.9	Landing Page: replace mock cooks	landing_page.dart	Use HomeRepository.recommendedRestaurants() to fetch real cook data for "Happening Now" section.
1.10	My Orders: fix avatar display	order_card.dart	Order API returns mikitchn.images[] and mikitchn.cock.avatar. Extract and show in CircleAvatar.
Sprint 2: Backend Route Fixes (Small backend + mobile changes)
These need minor backend changes — mostly registering existing controller methods.

#	Fix	Backend Change	Mobile Change
2.1	Notifications: register route	Add Route::get('notifications', [FcmController::class, 'getAllNotifications']) to api.php inside auth middleware group	Replace mock_notifications.dart with real API call in notifications_page.dart
2.2	Review: register route	Add Route::post('addreviewtorestaurant', [ReviewController::class, 'addReviewToRestaurant']) to api.php	submit_review_page.dart already calls this endpoint — will work once route exists
2.3	Kitchen open toggle: new endpoint	Add Route::post('v2/mikitchn/toggle-open', ...) — simple: $kitchen->update(['open' => !$kitchen->open])	Wire Kitchen Live Switch in home_cook_page.dart to call this endpoint
2.4	Order detail: new endpoint	Add Route::get('v2/orders/{id}', ...) — return single order with items, kitchen, customer	Wire order_tracking_page.dart to fetch fresh order data on load
2.5	Mark notification read	Add Route::put('notifications/{id}/read', ...) — set read_at = now()	Wire notification_tile.dart tap to mark as read
Sprint 3: UI Polish (Code-only, design alignment)
#	Fix	File(s)	What to Do
3.1	Discovery cook card sizing	discovery_cook_card.dart	Match design: larger hero image (200px height), rating badge top-left, distance pill bottom-right
3.2	Cook Profile Menu hero	order_menu_page.dart	Fix SliverAppBar parallax, add cook avatar overlapping hero bottom-left
3.3	Cart Checkout slide-to-pay	slide_to_pay_button.dart	Polish: add haptic feedback, improve thumb styling, add shimmer hint animation
3.4	Menu Item Tile layout	menu_item_tile.dart	Fix image aspect ratio (1:1 square), price right-aligned, 2-line description
3.5	Floating Cart Bar	floating_cart_bar.dart	Add slide-up animation on appear, polish shadow/gradient
3.6	Category Pills	discovery_category_pills.dart	Fix selected state: primary bg + white text, unselected: surfaceContainerLow + onSurface
3.7	Order Status Timeline	order_status_timeline.dart	Increase step icon size (24→32px), thicker connector line, add pulse animation on active step
3.8	Checkout Receipt	checkout_receipt.dart	Add divider before total, bold total row, larger font for total amount
3.9	Operating Hours dialog	timing_edit.dart	Add "Quick Status" summary at top (e.g., "Open Mon-Sat, Closed Sun"), improve time box tap targets
3.10	Edit Profile preferences	edit_profile_foodie_page.dart	Make dietary chips selectable (toggle local state), save to SharedPreferences for now
Sprint 4: New Backend Features (Larger effort)
#	Feature	Backend Work	Mobile Work
4.1	Dietary filter in discovery	Add special_diets query param to DiscoveryService::filtered(), filter by food's specialDiet field	Wire dietary chips in search_filters_page.dart to pass filter to HomeCubit
4.2	User dietary preferences	New migration: user_dietary_preferences table. New endpoints: GET/PUT /v2/account/preferences	Wire edit_profile_foodie to save/load preferences. Pre-fill search filters.
4.3	Review photo upload	Add photos file validation to ReviewController. Create review_images table + migration.	Wire submit_review photo picker to upload via multipart form
4.4	Expanded analytics	New endpoint GET /v2/account/analytics with date range param. Query orders grouped by day/week/month. Return top dishes by revenue.	Replace mock data in revenue_analytics_page.dart with real API response
4.5	Push notifications on order status	Enable broadcasting driver (Redis/Pusher). Add FCM notification dispatch in OrderController::statusUpdate().	Handle incoming FCM in notification_service.dart, refresh order tracking
Implementation Priority
Sprint 1 (Code-only) ← START HERE, fastest impact
  ↓
Sprint 2 (Backend routes) ← Small backend changes
  ↓
Sprint 3 (UI polish) ← Can run parallel with Sprint 2
  ↓
Sprint 4 (New features) ← Larger backend work
Sprint 1 alone makes the app demoable with real data everywhere. Sprints 1+2 make it functionally complete. Sprints 1+2+3 make it design-compliant. All 4 sprints make it fully publish-ready.

Files Summary
Sprint 1 (10 mobile files to modify)
lib/pages/favourites/view/favourites_page.dart
lib/pages/favourites/element/favourite_cook_card.dart
lib/pages/payments/view/payments_page.dart
lib/pages/home/view/search_filters_page.dart
lib/pages/home/element/discovery_cook_card.dart
lib/pages/home/view/home_page.dart
lib/pages_cook/home_page/view/home_cook_page.dart
lib/pages_cook/revenue_analytics/view/revenue_analytics_page.dart
lib/pages/ordering/view/order_tracking_page.dart
lib/pages/miorders/element/order_card.dart
Sprint 2 (5 backend + 4 mobile files)
backend/routes/api.php (add 5 routes)
backend/app/Http/Controllers/Api/MikitchnController.php (add toggleOpen)
backend/app/Http/Controllers/Api/OrderController.php (add show)
lib/pages/notifications/view/notifications_page.dart
lib/pages/notifications/element/notification_tile.dart
lib/pages_cook/home_page/view/home_cook_page.dart
lib/pages/ordering/view/order_tracking_page.dart
Sprint 3 (10 mobile widget files)
Various element widgets listed above
Sprint 4 (4 backend + 4 mobile)
New migrations, controllers, mobile integration
Verification per Sprint
Sprint 1: flutter analyze clean → build → install → test all screens show real data Sprint 2: Backend docker compose up --build → test new endpoints with curl → mobile build → test notifications, kitchen toggle, order detail Sprint 3: Visual comparison against design PNGs → build → install → screenshot comparison Sprint 4: Full integration test: signup → browse → order → track → review → notifications
