@extends('layouts.frontendlayout')

@section('content') 
<link rel='stylesheet' href='https://cdn.jsdelivr.net/npm/sweetalert2@10.10.1/dist/sweetalert2.min.css'>
<section class="contact-sec register-sec">
   <div class="loader-outer hide" id="loader-div">
      <img src="{{url('loader.gif')}}">
   </div>
   <div class="container">
      <div class="row align-items-center">
         <div class="col-md-6">
            <div class="contact-data">
               <h2>Registration</h2>
               <!-- <form action="https://mitabl.lightning.force.com/services/data/v53.0/sobjects/Lead" method="POST" id="registration"> -->
               <form action="/api/preregister" method="POST" id="registration">

                  <!--  ----------------------------------------------------------------------  -->
                  <!--  NOTE: These fields are optional debugging elements. Please uncomment    -->
                  <!--  these lines if you wish to test in debug mode.                          -->
                  <!--  <input type="hidden" name="debug" value=1>                              -->
                  <!--  <input type="hidden" name="debugEmail" value="support@mitabl.com">      -->
                  <!--  ----------------------------------------------------------------------  -->

                  <div class="form-outer">
                     <input id="first_name" maxlength="40" name="first_name" size="20" type="text" placeholder="First Name" />
                  </div>
                  <div class="form-outer">
                     <input id="last_name" maxlength="80" name="last_name" size="20" type="text" placeholder="Last Name" />
                  </div>
                  <div class="form-outer">
                     <input id="email" maxlength="80" name="email" size="20" type="text" placeholder="Email" />
                  </div>
                  <div class="form-outer phone-No">
                     <input id="mobile" maxlength="9" name="mobile" size="9" type="text" placeholder="Mobile" />
                     <span class="add-phone-before">+61</span>
                     <span style="display:none;" class="error error-phone">Please enter Australian phone number.</span> 
                  </div>
                  <div class="form-outer">
                     <input id="city" maxlength="40" name="city" size="20" type="text" placeholder="City" />
                  </div>
                  <div class="form-outer">
                     <!-- <select style="display:none;" id="00N5i000006uZtT" name="00N5i000006uZtT" title="Interested In">
                        <option value="">Select Interest</option>
                        <option value="micook">micook</option>
                        <option value="mifoodi">mifoodi</option>
                     </select> -->
                     <div class="radio-btns">
                        <span><input type="radio" value="micook" id="radio-micook" name="00N5i000006uZtT"> micook</span>
                        <span><input  type="radio" value="mifoodi" id="radio-mifoodi" name="00N5i000006uZtT"> mifoodi</span>
                     </div>
                     <span style="display:none;" class="error error-type">Please select user type.</span>
                  </div>
                  <!-- <div class="form-outer">
                     <input id="company" maxlength="40" name="Company" size="20" type="text" placeholder="Company" />
                  </div> -->
                  <div class="g-recaptcha" data-sitekey="{{ config('services.recaptcha.site_key') }}"></div><br>
                  <div class="form-outer">
                     <input type="submit" name="submit">
                     <!-- <input type="button" value="Submit" name="sfubmit"> -->
                     <!-- <a href="#">Submit</a> -->
                  </div>
               </form>
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
@push('scripts')
   <script src="https://www.google.com/recaptcha/api.js"></script>
   <script src="https://cdnjs.cloudflare.com/ajax/libs/jquery-validate/1.19.0/jquery.validate.js"></script>
   <script src="https://cdn.jsdelivr.net/npm/sweetalert2@10.16.6/dist/sweetalert2.all.min.js"></script>
   <script>
      let validationRules = {
             // Specify validation rules
             rules: {
               first_name: "required",
               last_name: "required",
               city: "required",
               email: {
                 required: true,
                 email: true
               },      
               mobile: {
                 required: true,
                 digits: true,
                 minlength: 9,
                 maxlength: 9,
               }
             },
             messages: {
               first_name: {
               required: "Please enter first name",
              },      
              last_name: {
               required: "Please enter last name",
              },     
              mobile: {
               required: "Please enter phone number",
               digits: "Please enter valid phone number",
               minlength: "Phone number field accept only 9 digits",
               maxlength: "Phone number field accept only 9 digits",
              },     
              email: {
               required: "Please enter email address",
               email: "Please enter a valid email address.",
              },
              city: {
               required: "Please enter city",
              },
             },
          
           }
      function formValidateCus() {
         // debugger
         $("#registration").validate(validationRules);
      }
      function validate_Phone_Number() {
          var number = $('#mobile').val();
          // console.log()
          var filter = /^(?:\+?(61))? ?(?:\((?=.*\)))?(0?[2-57-8])\)? ?(\d\d(?:[- ](?=\d{3})|(?!\d\d[- ]?\d[- ]))\d\d[- ]?\d[- ]?\d{3})$/;
          if (filter.test(number)) {
              return true;
          }
          else {
              return false;
          }
      }



      function sendAjaxReq(jsnData) {
         // var form = $('#registration').get(0);
         // $.removeData(form,'validator');
         // $("#registration").validate().settings.ignore = "*";
         // debugger
         let _ldr = $('#loader-div');
         jQuery.ajax({
                  type: 'post', 
                  // url: 'https://mitabl--test.sandbox.my.salesforce.com/services/data/v53.0/sobjects/Lead',
                  url: '/api/preregister',
                  data: JSON.stringify(jsnData),
                  contentType: 'application/json',
                  // crossDomain: true,
                  // headers: {
                  //    'Access-Control-Allow-Credentials':'true',
                  //    'Access-Control-Allow-Methods': 'GET, PUT, POST, DELETE, OPTIONS',
                  //    'Access-Control-Allow-Origin': '*',
                  //    'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Requested-With',
                  //    // 'Authorization':'Bearer '+accessTkn,  
                  //  },
                  beforeSend: function (request){
                     _ldr.removeClass('hide');
                     _ldr.addClass('show');
                  }, 
                  success: function (response) {
                     _ldr.removeClass('show');
                     _ldr.addClass('hide');
                     if (response.isSuccess) {
                        Swal.fire(
                          'Success!',
                          response.message,
                          'success'
                        ).then(function() {
                            document.getElementById('registration').reset()
                        });
                     }
                     
                     
                  },
                  error: function(response){
                     _ldr.removeClass('show');
                     _ldr.addClass('hide');
                     // console.log(response)
                     // debugger
                     if (!response.responseJSON.isSuccess) {
                        // debugger
                        Swal.fire(
                          'Error!',
                          response.responseJSON.isError,
                          'error'
                        )
                     }
                  }
         })
      }
$(document).ready(function(){
   $('#loader-div').addClass('hide')

   $("#mobile").keyup(function(){
      if (validate_Phone_Number()) {
         document.getElementsByClassName('error-phone')[0].style.display = 'none';
      } else {
         document.getElementsByClassName('error-phone')[0].style.display = 'block';
      }
   })

   $('input[type=radio][name=00N5i000006uZtT]').change(function() {
      document.getElementsByClassName('error-type')[0].style.display = 'none';
   });

  // $('input[name="sfubmit"]').on('click', function(e) {
  $("form").submit(function(e){
      e.preventDefault();
      let succdata = false;
      if (!$("input[name='00N5i000006uZtT']").is(':checked')) {
         succdata = false;
         document.getElementsByClassName('error-type')[0].style.display = 'block';
      } else {
         succdata = true;
         document.getElementsByClassName('error-type')[0].style.display = 'none';
      }

      if ($('#mobile').val()) {
         if (validate_Phone_Number()) {
            succdata = true;
            document.getElementsByClassName('error-phone')[0].style.display = 'none';
         } else {
            succdata = false;
            document.getElementsByClassName('error-phone')[0].style.display = 'block';
         }
          
         
      }
      const _formValid = formValidateCus();

      // console.log(succdata)
     if (succdata) {
      let _sndData = {
         FirstName: document.getElementById('first_name').value,
         LastName: document.getElementById('last_name').value, 
         Email: document.getElementById('email').value, 
         MobilePhone: document.getElementById('mobile').value, 
         City: document.getElementById('city').value, 
         mitabl_Interested_In__c: document.querySelector('input[name="00N5i000006uZtT"]:checked').value, 
         Company: "Not Aplicable",
      }

      setTimeout(function() {
         if (!$('#registration').validate().errorList.length) {
            sendAjaxReq(_sndData);
         }
      }, 500);
     }

  })
  formValidateCus()
});


</script>
   <script>
      $(document).ready(function(){
         // $( "input[type=radio][name=typeuser]" ).change(function() {
         //    if ($(this).val() == 1) {
         //       $('#00N5i000006uZtT option[value=mifoodi]').removeAttr("selected");
         //       $('#00N5i000006uZtT option[value=micook]').attr('selected','selected');
         //    } else {
         //       $('#00N5i000006uZtT option[value=micook]').removeAttr("selected");
         //       $('#00N5i000006uZtT option[value=mifoodi]').attr('selected','selected');
         //    }     

         // });

         
      })
   </script>


@endpush
