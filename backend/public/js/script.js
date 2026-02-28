
// import stripe from '../../stripe';

// stripe(window.STRIPE_PUBLISHABLE_KEY);

	// var elements = stripe.elements();
	// var cardElement = elements.create('card');
	// cardElement.mount('#card-element');
	$('#loader-div').addClass('hide')
	var cardholderName = document.getElementById('cardholder-name');
	// var cardholderCard = document.getElementById('cardholder-card');
	var cardholderExpdate = document.getElementById('cardholder-expdate');
	// var cardholderCvc = document.getElementById('cardholder-cvc');
	var cardButton = document.getElementById('card-button');
	var resultContainer = document.getElementById('card-result');

	var cardNumber = $('#cardholder-card');
	var cardholderExpd = $('#cardholder-expdate');
	var CVV = $("#cardholder-cvc");
	cardNumber.payform('formatCardNumber');
	CVV.payform('formatCardCVC');
	
	cardholderExpd.keyup(function() {
		// debugger
		$('#cardholder-expdate').samask("00/0000");
		// $.samaskHtml();
	})
	cardNumber.keyup(function() {

	    if ($.payform.validateCardNumber(cardNumber.val()) == false) {
	        cardNumber.removeClass('has-success');
	        cardNumber.addClass('has-error');
	    } else {
	        cardNumber.removeClass('has-error');
	        cardNumber.addClass('has-success');
	    }

	    // if ($.payform.parseCardType(cardNumber.val()) == 'visa') {
	    //     mastercard.addClass('transparent');
	    //     amex.addClass('transparent');
	    // } else if ($.payform.parseCardType(cardNumber.val()) == 'amex') {
	    //     mastercard.addClass('transparent');
	    //     visa.addClass('transparent');
	    // } else if ($.payform.parseCardType(cardNumber.val()) == 'mastercard') {
	    //     amex.addClass('transparent');
	    //     visa.addClass('transparent');
	    // }
	});

	// Start function
	// const saveCard = async function() {
	//   	const paymentMethod = await stripe.paymentMethods.create({
	// 	  type: 'card',
	// 	  card: {
	// 	    number: cardNumber.val(),
	// 	    exp_month: _expMnth,
	// 	    exp_year: _expYear,
	// 	    cvc: CVV.val(),
	// 	  },
	// 	}).then(function(result) {
	// 		if (result.error) {
	// 		  // Display error.message in your UI
	// 		  resultContainer.textContent = result.error.message;
	// 		} else {
	// 		  // You have successfully created a new PaymentMethod
	// 		  resultContainer.textContent = "Created payment method: " + result.paymentMethod.id;
	// 		}
	// 	});
	// }


	let _check = 0;

	cardButton.addEventListener('click', function(ev) {

		$('input').each(function(){
			if($(this).val() == ''){ 
		        _check++;
		        $(this).removeClass('has-success')
		        $(this).addClass('has-error')
		    } else {
		    	_check=0;
		    	$(this).removeClass('has-error')
		    	$(this).addClass('has-success')
		    }
		})

		let _cardExpdate = cardholderExpdate.value;
		// let _cardExpdate = cardholderExpdate.value.split('/');
		// let _expMnth = _cardExpdate[0]
		// let _expYear = _cardExpdate[1]
		if (_check == 0) {
			// console.log('djhsj')
			let _data = {name:cardholderName.value,card_number:cardNumber.val(),exp_date:_cardExpdate,cvc:CVV.val()}
			saveCard(_data)
		}
		
	});

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

	function saveCard(crDetails) {
		let _srch = getUrlParams(location.href)
		let _ldr = $('#loader-div');
		if (_srch.access) {
			$.ajax({
			    data: crDetails,
			    url: '/api/v1/addcard',
			    type: 'POST',
			    headers: {
			        'Authorization':'Bearer '+_srch.access,
			        'X-CSRF-TOKEN':$("meta[name='csrf-token']").attr('content'),
			    },
			    beforeSend: function (request) {
			    	_ldr.removeClass('hide');
			    	_ldr.addClass('show');

			        // return request.setRequestHeader('X-CSRF-Token', $("meta[name='csrf-token']").attr('content'));
			    },
			    success: function(response){
			    	_ldr.removeClass('show');
			    	_ldr.addClass('hide');
			    	if (response.isSuccess) {
			    		Swal.fire(
						  'Success!',
						  'Your Card Is Successfully Added!',
						  'success'
						)
			    	}
			    	
			        // console.log(response);
			    },
			    error: function(response){
			    	_ldr.removeClass('show');
			    	_ldr.addClass('hide');
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
