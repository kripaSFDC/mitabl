@extends('layouts.frontendlayout')

@section('content') 

<section class="contact-sec">
   <div class="container">
      <div class="row align-items-center">
         <div class="col-md-6">
            <div class="contact-data">
               <!-- <h2>Contact us</h2> -->
               <!-- <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Suspendisse tellus elit. </p> -->
               <form action="https://webto.salesforce.com/servlet/servlet.WebToCase?encoding=UTF-8" method="POST">

                  <input type=hidden name="orgid" value="00D5i000004SJla">
                  <input type=hidden name="retURL" value="https://www.mitabl.com/">

                  <div class="form-outer">

                     <select style="display:none;" id="recordType" name="recordType">
                        <option value="">--None--</option>
                        <option value="0125i00000097ZW">micook</option>
                        <option value="0125i00000097Zb">mifoodi</option>
                     </select>

                     <input style="display:none;" id="00N5i000009zQqb" maxlength="80" name="00N5i000009zQqb" size="20" type="text" />

                     <input style="display:none;" id="00N5i000009zQxr" maxlength="80" name="00N5i000009zQxr" size="20" type="text" />

                     <select  id="type" name="type" onchange="getval(this);">
                        <option value="">Type</option>
                        <option value="Registration">Registration</option>
                        <option value="Payment">Payment</option>
                        <option value="Complaint">Complaint</option>
                        <option value="Inquiry">Inquiry</option>
                        <option value="Other">Other</option>
                     </select>
                     
                  </div>
                  <div class="form-outer" id="order_id" style="display:none;">
                     <input id="00N5i000006ubH5" maxlength="40" name="00N5i000006ubH5" size="20" type="text" placeholder="Order Id" />
                  </div>
                  <div class="form-outer">
                     <input placeholder="Email" id="email" maxlength="80" name="email" size="20" type="text" />
                  </div>
                  <div class="form-outer">
                     <input placeholder="Phone" id="phone" maxlength="40" name="phone" size="20" type="text" />
                  </div>
                  <div class="form-outer">
                     <input placeholder="Subject" id="subject" maxlength="80" name="subject" size="20" type="text" /> 
                  </div>
                  <div class="form-outer">
                     <textarea name="description" placeholder="Description"></textarea>
                  </div>
                  <div class="form-outer">
                     <!-- <input type="submit" name="Submit"> -->
                     <a href="#">Submit</a>
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

         if (sel.value == 'Payment') {
            _orderSt = 'block';
         } else if (sel.value == 'Complaint') {
            _orderSt = 'block';
         } else {
            document.getElementById('00N5i000006ubH5').value = '';
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