@extends('layouts.frontendlayout')

@section('content')
<section class="about-section">
   <div class="container">
      <div class="row">
         <div class="col-md-12">
            <h2>Frequently Asked Questions</h2>
            <p>This FAQ is compiled from the current codebase and project documentation.</p>
         </div>
      </div>
   </div>
</section>

<section class="about-sec-2">
   <div class="container">
      <div class="row">
         <div class="col-md-12">
            <h3>Platform Basics</h3>
            <p><strong>What is mitabl?</strong><br>mitabl is a home-cooked food marketplace connecting Foodies (customers) with Cooks (miKitchen operators).</p>
            <p><strong>Which products/channels are currently active?</strong><br>The mobile app is the end-user product channel. The public website is marketing-only and unauthenticated. Internal staff workflows are handled in the backend admin portal.</p>

            <h3>Foodie FAQs</h3>
            <p><strong>What can Foodies do in the platform?</strong><br>Foodies can discover kitchens, browse menus, place orders, manage cards/payments, and leave reviews.</p>
            <p><strong>How do Foodies access these features?</strong><br>Foodie operational features are available through the mobile app and backend APIs (authenticated customer scope), not through website forms.</p>

            <h3>miCook / miKitchen FAQs</h3>
            <p><strong>What can Cooks (miKitchen operators) do?</strong><br>Cooks can manage kitchen profile/menu, handle incoming orders, update fulfillment status, and manage onboarding/certification workflows.</p>
            <p><strong>Where are kitchen and certificate operations managed internally?</strong><br>Operations and approvals are handled by mitabl staff through the authenticated admin portal in backend Filament resources.</p>

            <h3>Support & Trouble Tickets</h3>
            <p><strong>Is trouble-ticket management still available?</strong><br>Yes. CRM ticket creation, read, and reply flows are maintained in backend support-ticket APIs and admin tooling.</p>
            <p><strong>Can public website visitors create support tickets directly from this website?</strong><br>No. The website is stateless marketing-only and does not expose website-owned intake APIs or website DB persistence.</p>

            <h3>Platform Admin & CRM</h3>
            <p><strong>What does the admin portal include?</strong><br>Customer service CRM workflows, operations modules (including certificate handling), and platform administration capabilities as defined in the enhancement plan.</p>
            <p><strong>Who can access admin/CRM pages?</strong><br>Authenticated mitabl staff with role/permission-based access controls.</p>

            <h3>Security, Data, and Architecture</h3>
            <p><strong>Where does data persist?</strong><br>Persistence is centralized in backend services/datastore. The public website does not own application data models/migrations.</p>
            <p><strong>How is deployment segmented?</strong><br>Public marketing website, backend API, and ops/admin runtime are separated at deployment/routing level while sharing the same core backend domain model source of truth.</p>
         </div>
      </div>
   </div>
</section>
@endsection
