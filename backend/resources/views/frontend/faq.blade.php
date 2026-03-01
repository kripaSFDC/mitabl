<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>mitabl FAQ</title>

    <link rel="stylesheet" href="https://use.typekit.net/nzh0bps.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.2.0/css/bootstrap.min.css">
</head>

<body>
    <div class="container my-5">
        <h1 class="text-body text-center mb-4"><b>mitabl Platform FAQ</b></h1>
        <p class="text-body">This FAQ contains repository-backed facts from platform documentation, route definitions, and deployment configuration.</p>

        <h5 class="mt-4"><strong>Table of contents</strong></h5>
        <ul>
            <li><a href="#platform-overview" class="text-body">Platform overview</a></li>
            <li><a href="#product-surfaces" class="text-body">Product surfaces (website/mobile/admin)</a></li>
            <li><a href="#data-boundary" class="text-body">Data ownership and persistence boundary</a></li>
            <li><a href="#support-lifecycle" class="text-body">Support ticket lifecycle and CRM handling</a></li>
            <li><a href="#admin-security" class="text-body">Security/access model for admin portal</a></li>
            <li><a href="#routing-model" class="text-body">Deployment/routing model (/, /api, /admin)</a></li>
        </ul>

        <h3 class="text-body mt-5" id="platform-overview"><b>Platform overview</b></h3>
        <div class="accordion" id="platformOverviewAccordion">
            <div class="accordion-item">
                <h2 class="accordion-header" id="platformHeadingOne">
                    <button class="accordion-button" type="button" data-bs-toggle="collapse" data-bs-target="#platformCollapseOne" aria-expanded="true" aria-controls="platformCollapseOne">
                        What is the current platform structure?
                    </button>
                </h2>
                <div id="platformCollapseOne" class="accordion-collapse collapse show" aria-labelledby="platformHeadingOne" data-bs-parent="#platformOverviewAccordion">
                    <div class="accordion-body">
                        The target structure is one backend (<code>backend/</code>) for persistence and admin APIs, one website frontend (<code>website/</code>) for public marketing pages, and one mobile app (<code>mobile-app/</code>).
                    </div>
                </div>
            </div>
            <div class="accordion-item">
                <h2 class="accordion-header" id="platformHeadingTwo">
                    <button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#platformCollapseTwo" aria-expanded="false" aria-controls="platformCollapseTwo">
                        What was identified as duplicated in the legacy arrangement?
                    </button>
                </h2>
                <div id="platformCollapseTwo" class="accordion-collapse collapse" aria-labelledby="platformHeadingTwo" data-bs-parent="#platformOverviewAccordion">
                    <div class="accordion-body">
                        The cutover plan records duplicate model/entity surfaces in <code>website/</code> and <code>backend/</code>, including <code>User</code>, <code>Mikitchn</code>, <code>Order</code>, <code>Review</code>, <code>Foods</code>, and related lookup entities.
                    </div>
                </div>
            </div>
        </div>

        <h3 class="text-body mt-5" id="product-surfaces"><b>Product surfaces (website/mobile/admin)</b></h3>
        <div class="accordion" id="productSurfacesAccordion">
            <div class="accordion-item">
                <h2 class="accordion-header" id="surfacesHeadingOne">
                    <button class="accordion-button" type="button" data-bs-toggle="collapse" data-bs-target="#surfacesCollapseOne" aria-expanded="true" aria-controls="surfacesCollapseOne">
                        What is the website surface responsible for?
                    </button>
                </h2>
                <div id="surfacesCollapseOne" class="accordion-collapse collapse show" aria-labelledby="surfacesHeadingOne" data-bs-parent="#productSurfacesAccordion">
                    <div class="accordion-body">
                        The website is marketing-only and stateless. The cutover plan documents removal of website DB models/migrations and removal of website intake proxy logic.
                    </div>
                </div>
            </div>
            <div class="accordion-item">
                <h2 class="accordion-header" id="surfacesHeadingTwo">
                    <button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#surfacesCollapseTwo" aria-expanded="false" aria-controls="surfacesCollapseTwo">
                        What is the mobile surface tied to?
                    </button>
                </h2>
                <div id="surfacesCollapseTwo" class="accordion-collapse collapse" aria-labelledby="surfacesHeadingTwo" data-bs-parent="#productSurfacesAccordion">
                    <div class="accordion-body">
                        The repository keeps a dedicated <code>mobile-app/</code> surface, while <code>backend/routes/api.php</code> defines mobile-oriented routes for auth, profiles, notifications, kitchens, reviews, and orders.
                    </div>
                </div>
            </div>
            <div class="accordion-item">
                <h2 class="accordion-header" id="surfacesHeadingThree">
                    <button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#surfacesCollapseThree" aria-expanded="false" aria-controls="surfacesCollapseThree">
                        What is the admin surface?
                    </button>
                </h2>
                <div id="surfacesCollapseThree" class="accordion-collapse collapse" aria-labelledby="surfacesHeadingThree" data-bs-parent="#productSurfacesAccordion">
                    <div class="accordion-body">
                        The admin surface is a Filament panel with ID <code>admin</code>, default path <code>/admin</code>, admin auth guard, admin password broker, and navigation groups for Operations, Customer Support, and Platform.
                    </div>
                </div>
            </div>
            <div class="accordion-item">
                <h2 class="accordion-header" id="surfacesHeadingFour">
                    <button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#surfacesCollapseFour" aria-expanded="false" aria-controls="surfacesCollapseFour">
                        Which widgets are configured on the admin dashboard?
                    </button>
                </h2>
                <div id="surfacesCollapseFour" class="accordion-collapse collapse" aria-labelledby="surfacesHeadingFour" data-bs-parent="#productSurfacesAccordion">
                    <div class="accordion-body">
                        The panel registers widgets including operational snapshot/live widgets, integration health, CRM queue stats, CRM aging buckets, SLA health, system health summary, and daily orders/registrations charts.
                    </div>
                </div>
            </div>
        </div>

        <h3 class="text-body mt-5" id="data-boundary"><b>Data ownership and persistence boundary</b></h3>
        <div class="accordion" id="dataBoundaryAccordion">
            <div class="accordion-item">
                <h2 class="accordion-header" id="dataHeadingOne">
                    <button class="accordion-button" type="button" data-bs-toggle="collapse" data-bs-target="#dataCollapseOne" aria-expanded="true" aria-controls="dataCollapseOne">
                        Which component is the persistence authority?
                    </button>
                </h2>
                <div id="dataCollapseOne" class="accordion-collapse collapse show" aria-labelledby="dataHeadingOne" data-bs-parent="#dataBoundaryAccordion">
                    <div class="accordion-body">
                        Backend is the persistence authority. The cutover plan explicitly states backend should remain the only persistence authority.
                    </div>
                </div>
            </div>
            <div class="accordion-item">
                <h2 class="accordion-header" id="dataHeadingTwo">
                    <button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#dataCollapseTwo" aria-expanded="false" aria-controls="dataCollapseTwo">
                        What changed at the website persistence boundary?
                    </button>
                </h2>
                <div id="dataCollapseTwo" class="accordion-collapse collapse" aria-labelledby="dataHeadingTwo" data-bs-parent="#dataBoundaryAccordion">
                    <div class="accordion-body">
                        Website DB models and migrations were removed, website intake proxy endpoints were removed, and website API routes were replaced with fallback 404 JSON responses.
                    </div>
                </div>
            </div>
            <div class="accordion-item">
                <h2 class="accordion-header" id="dataHeadingThree">
                    <button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#dataCollapseThree" aria-expanded="false" aria-controls="dataCollapseThree">
                        Which duplicate entities were called out in the cutover validation?
                    </button>
                </h2>
                <div id="dataCollapseThree" class="accordion-collapse collapse" aria-labelledby="dataHeadingThree" data-bs-parent="#dataBoundaryAccordion">
                    <div class="accordion-body">
                        The plan lists duplicated entities such as <code>CookingStyles</code>, <code>Favorite</code>, <code>Foods</code>, <code>Mikitchn</code>, <code>Order</code>, <code>OrderData</code>, <code>PromoCode</code>, <code>Review</code>, <code>Role</code>, <code>SpecialDiet</code>, <code>User</code>, and <code>verifyOtp</code>.
                    </div>
                </div>
            </div>
        </div>

        <h3 class="text-body mt-5" id="support-lifecycle"><b>Support ticket lifecycle and CRM handling</b></h3>
        <div class="accordion" id="supportAccordion">
            <div class="accordion-item">
                <h2 class="accordion-header" id="supportHeadingOne">
                    <button class="accordion-button" type="button" data-bs-toggle="collapse" data-bs-target="#supportCollapseOne" aria-expanded="true" aria-controls="supportCollapseOne">
                        Which support ticket statuses are used in CRM operations?
                    </button>
                </h2>
                <div id="supportCollapseOne" class="accordion-collapse collapse show" aria-labelledby="supportHeadingOne" data-bs-parent="#supportAccordion">
                    <div class="accordion-body">
                        The SOP lifecycle is <code>open</code> → <code>in_progress</code> → <code>pending_user</code> → <code>resolved</code> → <code>closed</code>, and resolving requires a mandatory summary.
                    </div>
                </div>
            </div>
            <div class="accordion-item">
                <h2 class="accordion-header" id="supportHeadingTwo">
                    <button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#supportCollapseTwo" aria-expanded="false" aria-controls="supportCollapseTwo">
                        How are replies and internal notes handled?
                    </button>
                </h2>
                <div id="supportCollapseTwo" class="accordion-collapse collapse" aria-labelledby="supportHeadingTwo" data-bs-parent="#supportAccordion">
                    <div class="accordion-body">
                        Public <code>Reply</code> is requester-visible communication. <code>Internal note</code> is private context, and governance states internal notes are never customer-visible.
                    </div>
                </div>
            </div>
            <div class="accordion-item">
                <h2 class="accordion-header" id="supportHeadingThree">
                    <button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#supportCollapseThree" aria-expanded="false" aria-controls="supportCollapseThree">
                        What assignment and handoff rules are documented?
                    </button>
                </h2>
                <div id="supportCollapseThree" class="accordion-collapse collapse" aria-labelledby="supportHeadingThree" data-bs-parent="#supportAccordion">
                    <div class="accordion-body">
                        Teams start from <code>Unassigned</code> or <code>SLA Risk</code>, use <code>Assign to me</code> for ownership, include a reason for reassignment, and include a resolution summary on resolved tickets.
                    </div>
                </div>
            </div>
            <div class="accordion-item">
                <h2 class="accordion-header" id="supportHeadingFour">
                    <button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#supportCollapseFour" aria-expanded="false" aria-controls="supportCollapseFour">
                        Where are support ticket endpoints exposed in the backend API?
                    </button>
                </h2>
                <div id="supportCollapseFour" class="accordion-collapse collapse" aria-labelledby="supportHeadingFour" data-bs-parent="#supportAccordion">
                    <div class="accordion-body">
                        <code>backend/routes/api.php</code> defines <code>POST /api/support/ticket</code>, <code>GET /api/support/ticket/{id}</code>, and <code>POST /api/support/ticket/{id}/reply</code> with throttling middleware.
                    </div>
                </div>
            </div>
            <div class="accordion-item">
                <h2 class="accordion-header" id="supportHeadingFive">
                    <button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#supportCollapseFive" aria-expanded="false" aria-controls="supportCollapseFive">
                        What escalation ladder is defined for SLA breaches?
                    </button>
                </h2>
                <div id="supportCollapseFive" class="accordion-collapse collapse" aria-labelledby="supportHeadingFive" data-bs-parent="#supportAccordion">
                    <div class="accordion-body">
                        First-response SLA breach notifies assigned agent and team lead; resolution SLA breach notifies ops lead and platform admin; repeated patterns (&gt;3/day) trigger incident review and staffing adjustment.
                    </div>
                </div>
            </div>
        </div>

        <h3 class="text-body mt-5" id="admin-security"><b>Security/access model for admin portal</b></h3>
        <div class="accordion" id="adminSecurityAccordion">
            <div class="accordion-item">
                <h2 class="accordion-header" id="adminHeadingOne">
                    <button class="accordion-button" type="button" data-bs-toggle="collapse" data-bs-target="#adminCollapseOne" aria-expanded="true" aria-controls="adminCollapseOne">
                        How is access to <code>/admin</code> restricted at the edge?
                    </button>
                </h2>
                <div id="adminCollapseOne" class="accordion-collapse collapse show" aria-labelledby="adminHeadingOne" data-bs-parent="#adminSecurityAccordion">
                    <div class="accordion-body">
                        NGINX allows only private source ranges (10/8, 172.16/12, 192.168/16), denies all others, and rejects methods outside <code>GET|POST|PUT|PATCH|DELETE|HEAD|OPTIONS</code>.
                    </div>
                </div>
            </div>
            <div class="accordion-item">
                <h2 class="accordion-header" id="adminHeadingTwo">
                    <button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#adminCollapseTwo" aria-expanded="false" aria-controls="adminCollapseTwo">
                        What security headers or forwarded flags are set for admin traffic?
                    </button>
                </h2>
                <div id="adminCollapseTwo" class="accordion-collapse collapse" aria-labelledby="adminHeadingTwo" data-bs-parent="#adminSecurityAccordion">
                    <div class="accordion-body">
                        At <code>/admin/</code>, NGINX sets <code>Cache-Control: no-store</code> and forwards <code>X-Admin-Mfa-Required: 1</code> to the upstream admin service.
                    </div>
                </div>
            </div>
            <div class="accordion-item">
                <h2 class="accordion-header" id="adminHeadingThree">
                    <button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#adminCollapseThree" aria-expanded="false" aria-controls="adminCollapseThree">
                        What framework-level middleware protects the admin panel?
                    </button>
                </h2>
                <div id="adminCollapseThree" class="accordion-collapse collapse" aria-labelledby="adminHeadingThree" data-bs-parent="#adminSecurityAccordion">
                    <div class="accordion-body">
                        The admin panel enables session/cookie middleware, CSRF verification, and auth middleware with Filament <code>Authenticate</code> plus <code>RecordAdminAction</code>.
                    </div>
                </div>
            </div>
        </div>

        <h3 class="text-body mt-5" id="routing-model"><b>Deployment/routing model (/, /api, /admin)</b></h3>
        <div class="accordion" id="routingAccordion">
            <div class="accordion-item">
                <h2 class="accordion-header" id="routingHeadingOne">
                    <button class="accordion-button" type="button" data-bs-toggle="collapse" data-bs-target="#routingCollapseOne" aria-expanded="true" aria-controls="routingCollapseOne">
                        How are core routes split at ingress?
                    </button>
                </h2>
                <div id="routingCollapseOne" class="accordion-collapse collapse show" aria-labelledby="routingHeadingOne" data-bs-parent="#routingAccordion">
                    <div class="accordion-body">
                        Phase 0 ingress maps <code>/</code> to <code>marketing-web</code>, <code>/api/*</code> to <code>backend-api</code>, and <code>/admin/*</code> to <code>ops-admin</code>.
                    </div>
                </div>
            </div>
            <div class="accordion-item">
                <h2 class="accordion-header" id="routingHeadingTwo">
                    <button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#routingCollapseTwo" aria-expanded="false" aria-controls="routingCollapseTwo">
                        How is HTTPS enforced and which site-wide headers are present?
                    </button>
                </h2>
                <div id="routingCollapseTwo" class="accordion-collapse collapse" aria-labelledby="routingHeadingTwo" data-bs-parent="#routingAccordion">
                    <div class="accordion-body">
                        Port 80 is redirected to HTTPS. The HTTPS server sets HSTS, X-Content-Type-Options, X-Frame-Options, Referrer-Policy, and X-XSS-Protection headers.
                    </div>
                </div>
            </div>
            <div class="accordion-item">
                <h2 class="accordion-header" id="routingHeadingThree">
                    <button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#routingCollapseThree" aria-expanded="false" aria-controls="routingCollapseThree">
                        What API health endpoints are defined?
                    </button>
                </h2>
                <div id="routingCollapseThree" class="accordion-collapse collapse" aria-labelledby="routingHeadingThree" data-bs-parent="#routingAccordion">
                    <div class="accordion-body">
                        API health endpoints include <code>/api/health</code>, <code>/api/health/live</code>, <code>/api/health/startup</code>, and <code>/api/health/ready</code>.
                    </div>
                </div>
            </div>
            <div class="accordion-item">
                <h2 class="accordion-header" id="routingHeadingFour">
                    <button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#routingCollapseFour" aria-expanded="false" aria-controls="routingCollapseFour">
                        Are API login and registration endpoints currently present?
                    </button>
                </h2>
                <div id="routingCollapseFour" class="accordion-collapse collapse" aria-labelledby="routingHeadingFour" data-bs-parent="#routingAccordion">
                    <div class="accordion-body">
                        Yes. The API routes file includes <code>POST /api/login</code>, <code>POST /api/register</code>, <code>POST /api/verifyOtp</code>, and <code>POST /api/resendotp</code>.
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.2.0/js/bootstrap.bundle.min.js"></script>
</body>

</html>
