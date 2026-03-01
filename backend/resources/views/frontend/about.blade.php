@extends('layouts.frontendlayout')

@section('content')

<section class="about-section">
   <div class="container">
      <div class="row">
         <div class="col-md-6">
            <h2>About Us</h2>
         </div>
      </div>
   </div>
</section>


<section class="about-sec-2">
   <div class="container">
      <div class="row align-items-center">
         <div class="col-md-12">
            <div class="img-about2">
               <!-- <img src="{{url('frontend/images/logo4.png')}}"> -->
               <p>mitabl connects micooks and mifoodi through a mobile-first food marketplace designed for real local discovery.</p>
               <p>Our mission is to grow stronger food communities by combining delightful app experiences with trusted backend operations.</p>
               <p>We help local economies thrive by making it easier for cooks to serve nearby diners with confidence, clarity, and operational support.</p>

               <h3>Real Local Connections</h3>
               <p>mitabl turns everyday food moments into meaningful connections through:</p>
               <ul>
                  <li><b>Neighbourhood meal access:</b> discover home-cooked options near you and order in just a few taps.</li>
                  <li><b>Reliable fulfilment:</b> backend-supported workflows help cooks and customers stay in sync from order to handoff.</li>
                  <li><b>Community growth:</b> every order supports local talent and strengthens the people around you.</li>
               </ul>
               <p><b>mitabl: cook | discover | share | connect</b></p>
            </div>
         </div>
         
      </div>
   </div>
</section>

<section class="mission-section bg-lightgray">
   <div class="container">
      <div class="row">
         <div class="col-lg-6">
            <div class="inner-content">
               <img src="{{url('frontend/images/mission.png')}}">
               <h4>Our Mission</h4>
               <p>To build the world's most trusted mobile marketplace for local home-cooked food.</p>
            </div>
         </div>
         <div class="col-lg-6">
            <div class="inner-content">
               <img src="{{url('frontend/images/vision.png')}}">
               <h4>Our Vision</h4>
               <p>To become the leading platform where local cooks and food lovers connect through dependable digital experiences.</p>
            </div>
         </div>
      </div>
   </div>
</section>




<!-- The Modal -->
  <div class="modal fade" id="myModal">
    <div class="modal-dialog">
      <div class="modal-content">
      
        <!-- Modal Header -->
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal">&times;</button>
        </div>
        
        <!-- Modal body -->
        <div class="modal-body">
         <img src="{{url('frontend/images/rocket.png')}}">
          <h3>Coming Soon...</h3>
          <p>We are preparing something amazing and exciting for you.</p>
        </div>
        
        
      </div>
    </div>
  </div>



<!-- <section class="about-sec-3">
   <div class="container">
      <h2 class="value-title">Our Values</h2>
      <div class="row">
         <div class="col-md-4">
            <div class="value-boxes">
               <h3>Lorem ipsum dolor</h3>
               <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Suspendisse tellus elit, sagittis eget consequat vel, porttitor a mauris. ras maximus ex id purus mattis interdum quis et dui. Duis ornare vulputate scelerisque.</p>
            </div>
         </div>
         <div class="col-md-4">
            <div class="value-boxes">
               <h3>Lorem ipsum dolor</h3>
               <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Suspendisse tellus elit, sagittis eget consequat vel, porttitor a mauris. ras maximus ex id purus mattis interdum quis et dui. Duis ornare vulputate scelerisque.</p>
            </div>
         </div>
         <div class="col-md-4">
            <div class="value-boxes">
               <h3>Lorem ipsum dolor</h3>
               <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Suspendisse tellus elit, sagittis eget consequat vel, porttitor a mauris. ras maximus ex id purus mattis interdum quis et dui. Duis ornare vulputate scelerisque.</p>
            </div>
         </div>
         <div class="col-md-4">
            <div class="value-boxes">
               <h3>Lorem ipsum dolor</h3>
               <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Suspendisse tellus elit, sagittis eget consequat vel, porttitor a mauris. ras maximus ex id purus mattis interdum quis et dui. Duis ornare vulputate scelerisque.</p>
            </div>
         </div>
         <div class="col-md-4">
            <div class="value-boxes">
               <h3>Lorem ipsum dolor</h3>
               <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Suspendisse tellus elit, sagittis eget consequat vel, porttitor a mauris. ras maximus ex id purus mattis interdum quis et dui. Duis ornare vulputate scelerisque.</p>
            </div>
         </div>
         <div class="col-md-4">
            <div class="value-boxes">
               <h3>Lorem ipsum dolor</h3>
               <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Suspendisse tellus elit, sagittis eget consequat vel, porttitor a mauris. ras maximus ex id purus mattis interdum quis et dui. Duis ornare vulputate scelerisque.</p>
            </div>
         </div>
      </div>
   </div>
</section>

<section class="about-sec-4">
   <div class="container">
      <h2 class="value-title">How It Works?</h2>
      <div class="row">
         <div class="col-md-4">
            <div class="value-boxes value-boxes1">
               <h1>1</h1>
               <h3>Lorem ipsum dolor</h3>
               <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Suspendisse tellus elit, sagittis eget consequat vel, porttitor a mauris. ras maximus ex id purus mattis interdum quis et dui. Duis ornare vulputate scelerisque.</p>
            </div>
         </div>
         <div class="col-md-4">
            <div class="value-boxes value-boxes1">
               <h1>2</h1>
               <h3>Lorem ipsum dolor</h3>
               <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Suspendisse tellus elit, sagittis eget consequat vel, porttitor a mauris. ras maximus ex id purus mattis interdum quis et dui. Duis ornare vulputate scelerisque.</p>
            </div>
         </div>
         <div class="col-md-4">
            <div class="value-boxes value-boxes1">
               <h1>3</h1>
               <h3>Lorem ipsum dolor</h3>
               <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Suspendisse tellus elit, sagittis eget consequat vel, porttitor a mauris. ras maximus ex id purus mattis interdum quis et dui. Duis ornare vulputate scelerisque.</p>
            </div>
         </div>
      </div>
   </div>
</section>
 -->
@endsection