<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Admin step-up re-authentication window
    |--------------------------------------------------------------------------
    |
    | Sensitive actions (policy publish/rollback, refunds, account suspension,
    | high-risk platform setting updates) require step-up authentication.
    | Once an admin confirms their password, we allow a short grace window to
    | avoid repeated prompts while still enforcing re-authentication frequently.
    |
    */
    'reauth_minutes' => env('ADMIN_REAUTH_MINUTES', 15),
];
