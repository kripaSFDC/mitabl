<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Secure card entry</title>
    <style>
        body {
            margin: 0;
            font-family: Arial, sans-serif;
            background: #f6f3ee;
            color: #1e1b18;
        }

        .shell {
            max-width: 420px;
            margin: 0 auto;
            padding: 24px 20px 40px;
        }

        .panel {
            background: #ffffff;
            border-radius: 20px;
            padding: 20px;
            box-shadow: 0 16px 40px rgba(0, 0, 0, 0.08);
        }

        h1 {
            margin: 0 0 8px;
            font-size: 24px;
        }

        p {
            margin: 0 0 20px;
            line-height: 1.5;
            color: #5b5148;
        }

        label {
            display: block;
            margin-bottom: 8px;
            font-weight: 600;
        }

        input,
        #card-element {
            width: 100%;
            box-sizing: border-box;
            border: 1px solid #d5c9bc;
            border-radius: 14px;
            padding: 14px 16px;
            background: #fffdf9;
            margin-bottom: 16px;
        }

        button {
            width: 100%;
            border: 0;
            border-radius: 999px;
            padding: 14px 18px;
            background: #1e1b18;
            color: #ffffff;
            font-size: 16px;
            font-weight: 700;
            cursor: pointer;
        }

        button:disabled {
            opacity: 0.6;
            cursor: wait;
        }

        .error {
            margin-top: 14px;
            color: #b42318;
            font-weight: 600;
        }
    </style>
</head>
<body>
<div class="shell">
    <div class="panel">
        <h1>Use a different card</h1>
        <p>This card will be turned into a one-time Stripe payment method for your order checkout.</p>
        <label for="cardholder-name">Name on card</label>
        <input id="cardholder-name" type="text" placeholder="Cardholder name">
        <label for="card-element">Card details</label>
        <div id="card-element"></div>
        <button id="submit-button" type="button">Use this card</button>
        <div id="card-error" class="error" role="alert"></div>
    </div>
</div>

<script src="https://js.stripe.com/v3/"></script>
<script>
    const publishableKey = @json($publishableKey);
    const returnUrl = @json($returnUrl);
    const submitButton = document.getElementById('submit-button');
    const errorNode = document.getElementById('card-error');
    const nameNode = document.getElementById('cardholder-name');

    if (!publishableKey) {
        errorNode.textContent = 'Stripe publishable key is not configured.';
        submitButton.disabled = true;
    } else {
        const stripe = Stripe(publishableKey);
        const elements = stripe.elements();
        const cardElement = elements.create('card', {
            hidePostalCode: true,
        });
        cardElement.mount('#card-element');

        cardElement.on('change', function(event) {
            errorNode.textContent = event.error ? event.error.message : '';
        });

        submitButton.addEventListener('click', async function() {
            submitButton.disabled = true;
            errorNode.textContent = '';

            const response = await stripe.createPaymentMethod({
                type: 'card',
                card: cardElement,
                billing_details: {
                    name: nameNode.value || '',
                },
            });

            if (response.error) {
                errorNode.textContent = response.error.message || 'Unable to create payment method.';
                submitButton.disabled = false;
                return;
            }

            const url = new URL(returnUrl);
            url.searchParams.set('status', 'success');
            url.searchParams.set('payment_method_id', response.paymentMethod.id);
            window.location.replace(url.toString());
        });
    }
</script>
</body>
</html>
