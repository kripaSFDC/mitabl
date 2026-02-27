@extends('layouts.frontendlayout')

@section('content')  

<section class="slider-sec">
   <div id="demo" class="carousel slide" data-ride="carousel" data-interval="10000">
     <ul class="carousel-indicators">
       <li data-target="#demo" data-slide-to="0" class="active"></li>
       <li data-target="#demo" data-slide-to="1"></li>
       <li data-target="#demo" data-slide-to="2"></li>
     </ul>
     <div class="carousel-inner">
       <div class="carousel-item active">
         <img src="{{url('frontend/images/banner.png')}}" class="banner-img" alt="Los Angeles" width="1100" height="500">
         <div class="container">
            <div class="carousel-caption">
              <h3>mitabl, creating opportunities </h3>
              <p>mitabl is an the idea to create possibility from an opportunity in new ways,  by giving every cook a chance</p>
              <div class="logo-slider">
               <a data-toggle="modal" data-target="#myModal" href="#"><img src="{{url('frontend/images/google.png')}}"></a>

              <a data-toggle="modal" data-target="#myModal" href="#"><img src="{{url('frontend/images/app.png')}}"></a>
              </div>
            </div>   
         </div>    
       </div>
       <div class="carousel-item">
         <img src="{{url('frontend/images/slider-2.jpg')}}" class="banner-img" alt="Los Angeles" width="1100" height="500">
         <div class="container">
            <div class="carousel-caption">
              <h3>mitabl, building communities</h3>
              <p>mitabl bonded by a shared love of food, letyour dreams of cooking for others be a reality</p>
              <div class="logo-slider">
               <a href="#" data-toggle="modal" data-target="#myModal"><img src="{{url('frontend/images/google.png')}}"></a>
               <a href="#" data-toggle="modal" data-target="#myModal"><img src="{{url('frontend/images/app.png')}}"></a>
              </div>
            </div>   
         </div>
       </div>
       <div class="carousel-item">
         <img src="{{url('frontend/images/slider-3.jpg')}}" class="banner-img" alt="Los Angeles" width="1100" height="500">
         <div class="container">
            <div class="carousel-caption">
              <h3>break bread with mitabl</h3>
              <p>cook| eat |talk| share|connect </p>
              <div class="logo-slider">
               <a href="#" data-toggle="modal" data-target="#myModal"><img src="{{url('frontend/images/google.png')}}"></a>
               <a href="#" data-toggle="modal" data-target="#myModal"><img src="{{url('frontend/images/app.png')}}"></a>
              </div>
            </div>   
         </div>
       </div>
     </div>
   </div>
</section>

<section class="about-sec sec-padd">
   <div class="container">
      <div class="row align-items-center">
         <div class="col-md-6">
            <div class="left-about">
               <img src="{{url('frontend/images/logo1.png')}}">
               <p>Fancy a home cooked meal but don’t fancy cooking yourself? Jump onto to Mitabl app and explore  the  meals being supplied in your local community of micooks. Then simply,make a selection, place your  order and enjoy your meal. </p>
               <ul>
                  <li><b>Scroll:</b> Want to break bread? Jump onto our App and explore the dining and cuisine options in your neighbourhood. </li>
                  <li><b>Select:</b> Search our menus, connect with local micooks, select your food and dining options, and make payment through Stripe mitabl’s secure payment platform. </li>
                  <li><b>Eat:</b> Tuck in and enjoy! Eat great food, meet new neighbours and make memories. </li>
                  <li><b>Share:</b> The experience on social media with # mitabl, so more people can discover their own local food events too! </li>
               </ul>
            </div>
         </div>
         <div class="col-md-6">
            <div class="img-about">
               <img src="{{url('frontend/images/home1.jpg')}}">
            </div>
         </div>
      </div>
   </div>
</section>

<section class="about-sec sec-padd">
   <div class="container">
      <div class="row align-items-center">
         <div class="col-md-6 micook-col-1">
            <div class="img-about">
               <img src="{{url('frontend/images/home2.jpg')}}">
            </div>
         </div>
         <div class="col-md-6 micook-col-2">
            <div class="left-about">
               <img src="{{url('frontend/images/logo2.png')}}">
               <p>With our platform, everyone has the opportunity to showcase and serve their specialities to their communities, from a celebrity chef to a regular home cook. With our platform, anyone from anywhere can dominate the local cooking scene without even owning the state of the art dine-in restaurant. mitabl helps you achieve your goals and promotes rapid growth thanks to our thorough user interface and collaboration with network of mifoodi ready to savor what cooking</p>
               <ul>
                  <li><b>Apply:</b> submit your interest through the registration form to be approved as a micook.  </li>
                  <li><b>Prepare:</b> Get online and start cooking! Check your orders and bookings. Acknowledge the order from your mifoodi, provide them with any information or updates about their order. Make sure you pay attention to any dietary requirements or special requests. </li>
                  <li><b>Host:</b>  Welcome your mifoodi either with takeaway or to dine in.Make sure to deliver something your mamma would be proud of. </li>
                  <li><b>Post:</b> The experience on social media with #mitabl so more people can discover their own local food events too! </li>
               </ul>

            </div>
         </div>
         
      </div>
   </div>
</section>

<section class="about-sec sec-padd">
   <div class="container">
      <div class="row align-items-center">
         <div class="col-md-6">
            <div class="left-about">
               <img src="{{url('frontend/images/log03.png')}}">
               <p>Come join our ever growing list of partners, come on a journey with us and explore what it feel to be proud member of mitabl community</p>
            </div>
         </div>
         <div class="col-md-6">
            <div class="img-about">
               <img src="{{url('frontend/images/home3.jpg')}}">
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

@endsection