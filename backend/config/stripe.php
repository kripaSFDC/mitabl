<?php

return [
    'api_keys' => [
        'secret_key' => env('STRIPE_SECRET_KEY', ''), // Secret KEY: https://dashboard.stripe.com/account/apikeys
        'publishable_key' => env('STRIPE_PUBLISHABLE_KEY', ''),
    ],
    'client_id' => env('STRIPE_CLIENT_ID', ''), // Client ID: https://dashboard.stripe.com/account/applications/settings
    'redirect_uri' => env('STRIPE_REDIRECT_URI', '/api/stripe/callback'), // Redirect Uri https://dashboard.stripe.com/account/applications/settings
    'authorization_uri' => env('STRIPE_AUTHORIZATION_URI', 'https://connect.stripe.com/oauth/authorize'),
    'webhook_signing_secret' => env('STRIPE_WEBHOOK_SIGNING_SECRET', ''),
    'currency' => env('STRIPE_CURRENCY', 'aud'),
    'connected_account_country' => env('STRIPE_CONNECTED_ACCOUNT_COUNTRY', 'AU'),
];
