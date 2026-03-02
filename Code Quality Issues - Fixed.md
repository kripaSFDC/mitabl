## Code Quality Issues - (FIXED Usman)

1. **High - Authorization gaps on order actions let authenticated users act on other users’ orders.**  
   [OrderController.php:97](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [OrderController.php:341](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [OrderController.php:393](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [api.php:144](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [api.php:146](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [api.php:195](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/)

2. **High - Booking availability logic is incorrect: seat checks are not scoped to the target kitchen.**  
   checkBookedTimeByDate queries all dine-in orders without mikitchn_id filtering.  
   [OrderController.php:311](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/)

3. **High - SQL injection risk via raw distance SQL built from request coordinates.**  
   Lat/lon are interpolated into raw SQL strings without strict numeric validation/binding.  
   [Mikitchn.php:113](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [DiscoveryService.php:168](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [MikitchnController.php:356](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/)

4. **High - Password reset flow has implementation errors likely to break or misroute requests.**  
   Array passed where scalar email is expected; catch block won’t catch global exceptions as intended in this namespace pattern.  
   [ResetPasswordController.php:66](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [ResetPasswordController.php:76](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [ResetPasswordController.php:99](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [ResetPasswordController.php:103](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/)

5. **High - Payment flow is not idempotent and is non-transactional, enabling duplicate/inconsistent payment records.**  
   Repeated payment attempts create new rows; order and payment updates are separate operations; no unique guard on payments.order_id.  
   [OrderController.php:457](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [OrderController.php:461](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [OrderController.php:477](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [Order.php:81](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [2026_03_02_000100_harden_orders_and_payments_schema.php:165](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/)

6. **High - Order creation path lacks required validation and transaction boundaries, risking 500s and partial writes.**  
   Controller forwards raw payload; service assumes required keys and parses times directly.  
   [OrderController.php:494](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [OrderService.php:19](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [OrderService.php:46](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/)

7. **Medium - OTP/auth hardening is weak (4-digit OTP, no expiry enforcement, limited brute-force resistance).**  
   No OTP freshness check in verification path; resend can be triggered by user id input.  
   [AuthService.php:12](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [UserController.php:435](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [UserController.php:359](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [api.php:60](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [api.php:61](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/)

8. **Medium - Several state-changing operations are exposed as GET, which is unsafe for caches/crawlers and semantics.**  
   [api.php:153](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [api.php:180](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [api.php:207](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [api.php:265](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [api.php:262](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/)

9. **Medium - Discovery queries are expensive and redundant under load.**  
   Correlated subquery + join/grouping + extra withAvg + subquery-based count on each call.  
   [DiscoveryService.php:172](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [DiscoveryService.php:177](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [DiscoveryService.php:237](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/)

10. **Medium - API and web concerns are mixed in API controllers (views/redirect/session in API class).**  
    These methods are not API-shaped and contain unresolved imports for web types.  
    [ReviewController.php:113](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [ReviewController.php:126](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [ReviewController.php:145](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/)

11. **Medium - Duplicate legacy logic and thin V2 wrappers preserve old flaws and increase maintenance cost.**  
    [AccountController.php:11](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [DiscoveryController.php:11](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [PaymentsController.php:11](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [MikitchnController.php:217](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [MikitchnController.php:281](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/)

12. **Medium - Data deletion logic is manual and non-atomic, with mixed ORM/raw operations.**  
    Risk of partial cleanup and harder invariants.  
    [User.php:191](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [Mikitchn.php:152](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/)

13. **Low - Time-difference helper uses wrong format tokens (H:s:i), which can skew cancellation/refund timing logic.**  
    [Controller.php:160](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [Controller.php:168](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/)

14. **Low - Test suite around API behavior is largely string-contract assertions, not behavioral/integration coverage.**  
    This leaves many runtime/security regressions untested.  
    [ModuleEightNineTenContractTest.php:11](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [AdminIdentityBoundaryRegressionTest.php:23](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/), [StripeIntegrationContractTest.php:29](https://file+.vscode-resource.vscode-cdn.net/c%3A/Users/nowus/.vscode/extensions/openai.chatgpt-0.5.79-win32-x64/webview/)
