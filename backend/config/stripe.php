<?php

return [
    'api_keys' => [
        'secret_key' => '', // Secret KEY: https://dashboard.stripe.com/account/apikeys
        'publishable_key' => '',
    ],
    'client_id' => '',       // Client ID: https://dashboard.stripe.com/account/applications/settings
    'redirect_uri' => '/api/stripe/callback', // Redirect Uri https://dashboard.stripe.com/account/applications/settings
    'authorization_uri' => 'https://connect.stripe.com/oauth/authorize'
];
