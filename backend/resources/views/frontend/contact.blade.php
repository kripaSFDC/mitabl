@extends('layouts.frontendlayout')

@section('content') 

<section class="contact-sec">
   <div class="container">
      <div class="row align-items-center">
         <div class="col-md-6">
            <div class="contact-data">
               <!-- <h2>Contact us</h2> -->
               <!-- <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Suspendisse tellus elit. </p> -->
               <form action="/api/support/ticket" method="POST">

                  <div class="form-outer">
                     <select id="category" name="category" onchange="getval(this);">
                        <option value="">Type</option>
                        <option value="account">Registration</option>
                        <option value="payment">Payment</option>
                        <option value="order">Complaint</option>
                        <option value="general">Inquiry</option>
                        <option value="other">Other</option>
                     </select>
                     
                  </div>
                  <div class="form-outer" id="order_id" style="display:none;">
                     <input id="order_id_input" maxlength="40" name="order_id" size="20" type="text" placeholder="Order Id" />
                  </div>
                  <div class="form-outer">
                     <input placeholder="Email" id="email" maxlength="80" name="requester_email" size="20" type="text" />
                  </div>
                  <div class="form-outer">
                     <input placeholder="Phone" id="phone" maxlength="40" name="requester_phone" size="20" type="text" />
                  </div>
                  <div class="form-outer">
                     <input placeholder="Subject" id="subject" maxlength="80" name="subject" size="20" type="text" /> 
                  </div>
                  <div class="form-outer">
                     <textarea name="description" placeholder="Description"></textarea>
                  </div>
                  <div class="form-outer">
                     <button type="submit">Submit</button>
                  </div>
               </form>
            </div>
         </div>
         <div class="col-md-6">
            <div class="img-contact">
               <img src="{{url('frontend/images/contact1.png')}}">
            </div>
         </div>
         
      </div>
   </div>
</section>

@endsection

@push('scripts')
    <script>

      function getval(sel)
      {
         let _orderSt = 'none';
         let _orderParEl = document.getElementById('order_id');

         if (sel.value == 'payment') {
            _orderSt = 'block';
         } else if (sel.value == 'order') {
            _orderSt = 'block';
         } else {
            document.getElementById('order_id_input').value = '';
         }

         _orderParEl.style.display = _orderSt;
      }


      // $(document).ready(function() {

      //    // $('#type').on('change', function(){
      //    //    if ($(this).val() == 'Payment') {

      //    //    }
      //    // })


      // })

    </script>
@endpush
