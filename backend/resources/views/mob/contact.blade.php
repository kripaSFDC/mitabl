@extends('layouts.moblayout')

@section('content') 
<link rel='stylesheet' href='https://cdn.jsdelivr.net/npm/sweetalert2@10.10.1/dist/sweetalert2.min.css'>
<section class="contact-sec">
   <div class="loader-outer hide" id="loader-div">
      <img src="{{url('loader.gif')}}">
   </div>
   <div class="container">
      <div class="row align-items-center">
         <div class="col-md-6">
            <div class="contact-data">
               <!-- <h2>Contact us</h2> -->
               <!-- <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Suspendisse tellus elit. </p> -->
               <form action="/api/support/ticket" method="POST" id="mob-contact">

                  <div class="form-outer">
                     <select id="category" name="category" onchange="getval(this);">
                        <option value="">Query Type</option>
                        <option value="account">Registration</option>
                        <option value="payment">Payment</option>
                        <option value="order">Complaint</option>
                        <option value="general">Inquiry</option>
                        <option value="other">Other</option>
                     </select>
                     
                  </div>
                  <div class="form-outer" id="order_id" style="display:none;">
                     <input id="order_id_input" maxlength="40" name="order_id" size="20" type="text" placeholder="Order Id" />
                     <span style="display:none;" class="error error-type">Please enter order id.</span>
                  </div>
                  <div class="form-outer">
                     <input placeholder="Email" id="email" maxlength="80" name="requester_email" size="20" type="text" />
                  </div>
                  <div class="form-outer phone-No">
                     <input placeholder="Phone" id="phone" maxlength="9" name="requester_phone" size="9" type="text" />
                     <span class="add-phone-before">+61</span>
                     <span style="display:none;" class="error error-phone">Please enter Australian phone number.</span> 
                  </div>
                  <div class="form-outer">
                     <input placeholder="Subject" id="subject" maxlength="80" name="subject" size="20" type="text" /> 
                  </div>
                  <div class="form-outer">
                     <textarea id="description" name="description" placeholder="Description"></textarea>
                  </div>
                  <div class="form-outer">
                     <input type="submit" name="Submit">
                     <!-- <input type="button" value="Submit" name="Submit"> -->
                     <!-- <a href="#">Submit</a> -->
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
<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.12.4/jquery.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/sweetalert2@10.16.6/dist/sweetalert2.all.min.js"></script>
   <script src="https://cdnjs.cloudflare.com/ajax/libs/jquery-validate/1.19.0/jquery.validate.js"></script>
 
    <script>
      $(document).ready(function(){

         jQuery.validator.addMethod("noSpace", function(value, element) { 
           return value.indexOf(" ") < 0 && value != ""; 
         }, "No space please and don't leave it empty");

      });

      let checkVisible = false;

      function getUrlParams(urlOrQueryString) {
         var i = null
        if (( i = urlOrQueryString.indexOf('?')) >= 0) {
          const queryString = urlOrQueryString.substring(i+1);
          if (queryString) {
            return _mapUrlParams(queryString);
          } 
        }
        
        return {};
      }

      function _mapUrlParams(queryString) {
        return queryString    
          .split('&') 
          .map(function(keyValueString) { return keyValueString.split('=') })
          .reduce(function(urlParams, [key, value]) {
            if (Number.isInteger(parseInt(value)) && parseInt(value) == value) {
              urlParams[key] = parseInt(value);
            } else {
              urlParams[key] = decodeURI(value);
            }
            return urlParams;
          }, {});
      }

      function getval(sel)
      {
         let _orderSt = 'none';
         let _orderParEl = document.getElementById('order_id');
         let _orderValEl = document.getElementById('order_id_input');
         if (sel.value == 'payment') {
            _orderSt = 'block';
            checkVisible = true;
            // _orderValEl.required = true;
         } else if (sel.value == 'order') {
            _orderSt = 'block';
            checkVisible = true;
            // _orderValEl.required = true;
         } else {
            // _orderValEl.required = false;
            _orderValEl.value = '';
         }
         _orderParEl.style.display = _orderSt;
      }

      function getUserType() {
         let _srch = getUrlParams(location.href)
         
         if (_srch.access) {
            $.ajax({
                url: '/api/v1/mob-contact',
                type: 'GET',
                dataType: 'json',
                headers: {
                    'Authorization':'Bearer '+_srch.access,
                    'X-CSRF-TOKEN':$("meta[name='csrf-token']").attr('content'),
                },
                success: function(response){

                  if (response.isSuccess) {
                     // console.log(response.data)
                     let _phnNo = response.data.phone.toString()
                     $('#email').val(response.data.email)
                     $('#phone').val(parseInt(_phnNo.substring(2).trim()))
                  }
                  
                },
                error: function(response){
                  
                  if (!response.responseJSON.isSuccess) {
                     Swal.fire(
                       'Error!',
                       response.responseJSON.isError,
                       'error'
                     )
                  }
                    // console.log(response.responseJSON);
                }
            })
         }
         
      }

      function validate_Phone_Number() {
          var number = $('#phone').val();
          // console.log()
          var filter = /^(?:\+?(61))? ?(?:\((?=.*\)))?(0?[2-57-8])\)? ?(\d\d(?:[- ](?=\d{3})|(?!\d\d[- ]?\d[- ]))\d\d[- ]?\d[- ]?\d{3})$/;
          if (filter.test(number)) {
              return true;
          }
          else {
              return false;
          }
      }

      function formValidateCus(){
         
         $("#mob-contact").validate({
             // Specify validation rules
             rules: {
               category: "required",
               subject: {
                  required: true,
                  noSpace: true
               },
               description: {
                  required: true,
                  noSpace: true
               }, 
              requester_email: {
                 required: true,
                 email: true
               },      
              requester_phone: {
                 required: true,
                 digits: true,
                 minlength: 9,
                 maxlength: 9,
               }
             },
             messages: {
              category: {
               required: "Please select type",
              },     
              subject: {
               required: "Please enter subject",
              },
              description: {
               required: "Please enter description",
              },     
             requester_phone: {
               required: "Please enter phone number",
               digits: "Please enter valid phone number",
               minlength: "Phone number field accept only 9 digits",
               maxlength: "Phone number field accept only 9 digits",
              },     
             requester_email: {
               required: "Please enter email address",
               email: "Please enter a valid email address.",
              }
             },
          
           });
      }

      function sendAjaxReq(jsnData) {
         let _ldr = $('#loader-div');
         jQuery.ajax({
                  type: 'post', 
                 url: '/api/support/ticket',
                  data: JSON.stringify(jsnData),
                  contentType: 'application/json',
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
                            document.getElementById('mob-contact').reset()
                            window.location.href = window.location.origin + "/?success=true";
                        });
                     }
                     
                     
                  },
                  error: function(response){
                     _ldr.removeClass('show');
                     _ldr.addClass('hide');
                     // console.log(response)
                     // debugger
                     if (!response.responseJSON.isSuccess) {
                        if (response.responseJSON.body) {
                           Swal.fire(
                             'Error!',
                             response.responseJSON.body[0].message,
                             'error'
                           )
                        }else{
                           Swal.fire(
                             'Error!',
                             response.responseJSON.isError,
                             'error'
                           )
                        }
                        
                     }
                  }
         })
      }

      function validatePhoneNo() {
         if (validate_Phone_Number()) {
            document.getElementsByClassName('error-phone')[0].style.display = 'none';
         } else {
            document.getElementsByClassName('error-phone')[0].style.display = 'block';
         }
      }

      $(document).ready(function(){
         $("#phone").keyup(function(){
            validatePhoneNo()
         })
         $("#order_id_input").keyup(function(){
            document.getElementsByClassName('error-type')[0].style.display = 'none';
         })
         $('form').submit(function(e) {
            e.preventDefault();
            let succdata = 0;
            if ($('#order_id').is(':visible')) {
               let _ordrval = document.getElementById('order_id_input').value;
               
               if (_ordrval == null) {
                  succdata--;
                  document.getElementsByClassName('error-type')[0].style.display = 'block';
               } else if (_ordrval == '') {
                  succdata--;
                  document.getElementsByClassName('error-type')[0].style.display = 'block';
               } else {
                  succdata++;
                  document.getElementsByClassName('error-type')[0].style.display = 'none';
               }
            } else {
               succdata++;
               document.getElementsByClassName('error-type')[0].style.display = 'none';
            }

            if ($('#phone').val()) {
               if (validate_Phone_Number()) {
                  succdata++;
                  document.getElementsByClassName('error-phone')[0].style.display = 'none';
               } else {
                  succdata--;
                  document.getElementsByClassName('error-phone')[0].style.display = 'block';
               }
                
               
            }
            

           formValidateCus()
           
            if (succdata) {
               let _sndData = {
                  category: document.getElementById('category').value,
                  order_id: document.getElementById('order_id_input').value,
                  requester_email: document.getElementById('email').value,
                  requester_phone: document.getElementById('phone').value,
                  subject: document.getElementById('subject').value,
                  description: document.getElementById('description').value,
               }
               // $( "#mob-contact" ).submit();
               setTimeout(function() {
                  if (!$('#mob-contact').validate().errorList.length) {
                     sendAjaxReq(_sndData);
                  }
               }, 500);
            }
        })

          

        getUserType()
        formValidateCus()
        // validatePhoneNo()

      })
      

    </script>
@endpush
