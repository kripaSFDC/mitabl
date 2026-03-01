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
        'max_files' => 5,
        'max_size_kb' => 5120,
        'allowed_mime_types' => [
            'image/jpeg',
            'image/png',
            'application/pdf',
            'text/plain',
        ],
        'blocked_extensions' => [
            'exe',
            'bat',
            'cmd',
            'com',
            'scr',
            'ps1',
            'php',
            'phar',
            'phtml',
            'js',
            'vbs',
            'jar',
            'msi',
        ],
    ],

    'pii_redaction' => [
        'enabled' => true,
    ],

    'routing' => [
        'default_assignee_id' => null,
        'rules' => [
            'category' => [
                'payment' => null,
                'order_dispute' => null,
                'account' => null,
                'general' => null,
                'other' => null,
            ],
            'priority' => [
                'urgent' => null,
                'high' => null,
            ],
        ],
    ],
];
