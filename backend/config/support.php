<?php

return [
    'duplicate_window_minutes' => 10,
    'reopen_window_hours' => 72,
    'honeypot_field' => 'website',

    'sla' => [
        'default' => [
            'first_response_minutes' => 60,
            'resolution_minutes' => 24 * 60,
        ],
        'priority_overrides' => [
            'low' => [
                'first_response_minutes' => 120,
                'resolution_minutes' => 48 * 60,
            ],
            'normal' => [
                'first_response_minutes' => 60,
                'resolution_minutes' => 24 * 60,
            ],
            'high' => [
                'first_response_minutes' => 30,
                'resolution_minutes' => 8 * 60,
            ],
            'urgent' => [
                'first_response_minutes' => 15,
                'resolution_minutes' => 4 * 60,
            ],
        ],
    ],

    'attachments' => [
        'max_files' => (int) env('SUPPORT_ATTACHMENT_MAX_FILES', 5),
        'max_size_kb' => (int) env('SUPPORT_ATTACHMENT_MAX_SIZE_KB', 5120),
        'allowed_mime_types' => explode(',', (string) env(
            'SUPPORT_ATTACHMENT_ALLOWED_MIME_TYPES',
            'image/jpeg,image/png,application/pdf,text/plain'
        )),
        'blocked_extensions' => explode(',', (string) env(
            'SUPPORT_ATTACHMENT_BLOCKED_EXTENSIONS',
            'exe,bat,cmd,com,scr,ps1,php,phar,phtml,js,vbs,jar,msi'
        )),
    ],

    'pii_redaction' => [
        'enabled' => (bool) env('SUPPORT_PII_REDACTION_ENABLED', true),
    ],

    'routing' => [
        'default_assignee_id' => env('SUPPORT_ROUTING_DEFAULT_ASSIGNEE_ID'),
        'rules' => [
            'category' => [
                'payment' => env('SUPPORT_ROUTING_PAYMENT_ASSIGNEE_ID'),
                'order_dispute' => env('SUPPORT_ROUTING_ORDER_ASSIGNEE_ID'),
                'account' => env('SUPPORT_ROUTING_ACCOUNT_ASSIGNEE_ID'),
                'general' => env('SUPPORT_ROUTING_GENERAL_ASSIGNEE_ID'),
                'other' => env('SUPPORT_ROUTING_OTHER_ASSIGNEE_ID'),
            ],
            'priority' => [
                'urgent' => env('SUPPORT_ROUTING_URGENT_ASSIGNEE_ID'),
                'high' => env('SUPPORT_ROUTING_HIGH_ASSIGNEE_ID'),
            ],
        ],
    ],
];
