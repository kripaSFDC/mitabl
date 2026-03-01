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
        <p class="text-body">This FAQ summarizes explicit implementation details from the repository documentation, route definitions, and deployment configuration.</p>

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
                        The repository is aligned to three surfaces: one backend (<code>backend/</code>) for persistence and admin APIs, one frontend (<code>website/</code>) for public marketing pages, and one mobile app (<code>mobile-app/</code>).
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
                        The website surface is marketing-only and stateless, with website DB models/migrations removed and website API intake proxy logic removed.
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
                        The target structure explicitly keeps <code>mobile-app/</code> as a dedicated product surface, while backend API routes under <code>/api</code> include authentication, account, order, and kitchen endpoints used by app clients.
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
                        The admin surface is a Filament panel configured with ID <code>admin</code>, default path <code>/admin</code>, admin auth guard, admin password broker, and grouped navigation for Operations, Customer Support, and Platform.
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
                        Backend is the persistence authority. The cutover plan records that duplicated website entities were removed and confirms backend should remain the only persistence authority.
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
                        Website DB models, migrations, and intake proxy APIs were removed. Website API routes were replaced with fallback 404 JSON responses to keep the website stateless.
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
                        The documented workflow progresses through: <code>open</code> → <code>in_progress</code> → <code>pending_user</code> → <code>resolved</code> → <code>closed</code>. Resolve requires a mandatory summary before closure.
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
                        Public Reply is used for requester-visible communication. Internal note is private context, and governance states internal notes are never customer-visible.
                    </div>
                </div>
            </div>
            <div class="accordion-item">
                <h2 class="accordion-header" id="supportHeadingThree">
                    <button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#supportCollapseThree" aria-expanded="false" aria-controls="supportCollapseThree">
                        Where are support ticket endpoints exposed in the backend API?
                    </button>
                </h2>
                <div id="supportCollapseThree" class="accordion-collapse collapse" aria-labelledby="supportHeadingThree" data-bs-parent="#supportAccordion">
                    <div class="accordion-body">
                        The backend API defines support ticket routes at <code>POST /api/support/ticket</code>, <code>GET /api/support/ticket/{id}</code>, and <code>POST /api/support/ticket/{id}/reply</code>, each with route-level throttling middleware.
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
                        NGINX limits <code>/admin/</code> to private ranges (10/8, 172.16/12, 192.168/16), denies all other sources, enforces an allowed HTTP method list, sets <code>Cache-Control: no-store</code>, and forwards <code>X-Admin-Mfa-Required: 1</code>.
                    </div>
                </div>
            </div>
            <div class="accordion-item">
                <h2 class="accordion-header" id="adminHeadingTwo">
                    <button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#adminCollapseTwo" aria-expanded="false" aria-controls="adminCollapseTwo">
                        What authentication/middleware stack protects the admin panel app?
                    </button>
                </h2>
                <div id="adminCollapseTwo" class="accordion-collapse collapse" aria-labelledby="adminHeadingTwo" data-bs-parent="#adminSecurityAccordion">
                    <div class="accordion-body">
                        The Filament admin panel uses admin guard authentication, admin password broker, session and CSRF middleware, plus auth middleware that includes Filament <code>Authenticate</code> and <code>RecordAdminAction</code>.
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
                        Phase 0 ingress maps <code>/</code> to <code>marketing-web</code>, <code>/api/*</code> to <code>backend-api</code>, and <code>/admin/*</code> to <code>ops-admin</code>. HTTP traffic is redirected to HTTPS.
                    </div>
                </div>
            </div>
            <div class="accordion-item">
                <h2 class="accordion-header" id="routingHeadingTwo">
                    <button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#routingCollapseTwo" aria-expanded="false" aria-controls="routingCollapseTwo">
                        What API health endpoints are defined?
                    </button>
                </h2>
                <div id="routingCollapseTwo" class="accordion-collapse collapse" aria-labelledby="routingHeadingTwo" data-bs-parent="#routingAccordion">
                    <div class="accordion-body">
                        Backend API includes <code>/api/health</code>, <code>/api/health/live</code>, <code>/api/health/startup</code>, and <code>/api/health/ready</code> for status and readiness reporting.
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.2.0/js/bootstrap.bundle.min.js"></script>
</body>

</html>
