@extends('layouts.frontendlayout')

@section('content')
<section class="about-section">
   <div class="container">
      <div class="row">
         <div class="col-md-12">
            <h2>Frequently Asked Questions</h2>
            <p>Find quick answers about how mitabl works today across mobile experiences and backend operations.</p>
         </div>
      </div>
   </div>
</section>

<section class="about-sec-2">
   <div class="container">
      <div class="row">
         <div class="col-md-12">
            <h3>Platform Basics</h3>
            <p><strong>What is mitabl?</strong><br>mitabl is a local food marketplace connecting Foodies (customers) with micooks through a mobile-first experience.</p>
            <p><strong>Which products are currently active?</strong><br>The mobile app is the primary customer channel. The website provides marketing information, while operational workflows run in mitabl's backend systems.</p>

            <h3>Foodie FAQs</h3>
            <p><strong>What can Foodies do?</strong><br>Discover local kitchens, browse menus, place orders, manage payments, and leave reviews in the mobile app.</p>
            <p><strong>Can I order from the website?</strong><br>No. Ordering and account workflows are managed in the mobile app.</p>

            <h3>micook FAQs</h3>
            <p><strong>What can micooks manage?</strong><br>micooks can maintain kitchen profiles, publish menus, manage incoming orders, and update fulfilment progress.</p>
            <p><strong>How are compliance and approvals handled?</strong><br>Operational review and approval processes are handled by mitabl teams through authenticated backend tools.</p>

            <h3>Support & Operations</h3>
            <p><strong>Is customer support available?</strong><br>Yes. Support and CRM workflows are maintained through backend tooling used by authorized mitabl staff.</p>
            <p><strong>Where is platform data stored?</strong><br>Application data is handled by backend services. The public marketing website does not own transactional customer data.</p>
         </div>
      </div>
   </div>
</section>
@endsection
