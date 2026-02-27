<!DOCTYPE html>
<html>
<head>
	<meta charset="utf-8">
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<title>mitabl save card details</title>
	<!-- CSRF Token -->
	<meta name="csrf-token" content="{{ csrf_token() }}">
	<!-- Fonts -->
	<link rel="dns-prefetch" href="//fonts.gstatic.com">
	<link href="https://fonts.googleapis.com/css?family=Nunito" rel="stylesheet">
	<!-- Styles -->
	<!-- <link href="{{ url('css/app.css') }}" rel="stylesheet"> -->
	<!-- boostrap -->
	<link rel="stylesheet" type="text/css" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.4/css/bootstrap.min.css">
	<link rel="stylesheet" type="text/css" href="https://maxcdn.bootstrapcdn.com/font-awesome/4.3.0/css/font-awesome.min.css">
	<link rel='stylesheet' href='https://cdn.jsdelivr.net/npm/sweetalert2@10.10.1/dist/sweetalert2.min.css'>
	<!-- calling custom css -->
	<link rel="stylesheet" type="text/css" href="{{ url('css/style.css') }}">
	<link rel="stylesheet" type="text/css" href="{{ url('css/responsive.css') }}">
</head>
<body>

	<div class="loader-outer hide" id="loader-div">
		<img src="{{url('loader.gif')}}">
	</div>

	<div class="outer-form">
		<!-- <input id="cardholder-name" type="text">
		 placeholder for Elements 
		<div id="card-element"></div>
		<div id="card-result"></div>
		<button id="card-button">Save Card</button> -->
		<div class="form-cont">
			<label>Name on card</label>
			<input id="cardholder-name" type="text">
		</div>
		<div class="form-cont">
			<label>Card Number</label>
			<input id="cardholder-card" type="text" placeholder="0000-0000-0000-0000">
		</div>
		<div class="form-cont divide-div">
			<div class="inner-div-50">
				<label>Expiration date</label>
				<input id="cardholder-expdate" type="text" placeholder="MM/YY">
			</div>
			<div class="inner-div-50">
				<label>Security code</label>
				<input id="cardholder-cvc" type="text" placeholder="CVC">
			</div>
		</div>
		<div class="form-cont btn-outer">
			<button type="button" id="card-button">SAVE CARD</button>
		</div>
		<div id="card-result"></div>
	</div>
	
	<!--<div class="outer-card-div">
		<input id="cardholder-name" type="text"> -->
		<!-- placeholder for Elements -->
		<!-- <div id="card-element"></div>
		<div id="card-result"></div>
		<button id="card-button">Save Card</button>
	</div> -->
	
<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.12.4/jquery.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/sweetalert2@10.16.6/dist/sweetalert2.all.min.js"></script>
<script src="{{ url('js/jquery.payform.min.js') }}"></script>
<script src="{{ url('js/jquery.samask-masker.js') }}"></script>
<!-- <script src="https://js.stripe.com/v3/"></script> -->
<!-- <script src="https://requirejs.org/docs/release/2.3.5/minified/require.js"></script> -->
<script type="module" src="{{ url('js/script.js') }}"></script>
<!-- <script>


var cardholderName = document.getElementById('cardholder-name');
var cardButton = document.getElementById('card-button');
var resultContainer = document.getElementById('card-result');

	
</script> -->
</body>
</html>