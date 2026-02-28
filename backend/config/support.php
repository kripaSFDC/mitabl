<?php

return [
    'duplicate_window_minutes' => (int) env('SUPPORT_DUPLICATE_WINDOW_MINUTES', 10),
    'reopen_window_hours' => (int) env('SUPPORT_REOPEN_WINDOW_HOURS', 72),
    'honeypot_field' => env('SUPPORT_HONEYPOT_FIELD', 'website'),

    'sla' => [
        'default' => [
            'first_response_minutes' => (int) env('SUPPORT_SLA_FIRST_RESPONSE_MINUTES', 60),
            'resolution_minutes' => (int) env('SUPPORT_SLA_RESOLUTION_MINUTES', 24 * 60),
        ],
        'priority_overrides' => [
            'low' => [
                'first_response_minutes' => (int) env('SUPPORT_SLA_LOW_FIRST_RESPONSE_MINUTES', 120),
                'resolution_minutes' => (int) env('SUPPORT_SLA_LOW_RESOLUTION_MINUTES', 48 * 60),
            ],
            'normal' => [
                'first_response_minutes' => (int) env('SUPPORT_SLA_NORMAL_FIRST_RESPONSE_MINUTES', 60),
                'resolution_minutes' => (int) env('SUPPORT_SLA_NORMAL_RESOLUTION_MINUTES', 24 * 60),
            ],
            'high' => [
                'first_response_minutes' => (int) env('SUPPORT_SLA_HIGH_FIRST_RESPONSE_MINUTES', 30),
                'resolution_minutes' => (int) env('SUPPORT_SLA_HIGH_RESOLUTION_MINUTES', 8 * 60),
            ],
            'urgent' => [
                'first_response_minutes' => (int) env('SUPPORT_SLA_URGENT_FIRST_RESPONSE_MINUTES', 15),
                'resolution_minutes' => (int) env('SUPPORT_SLA_URGENT_RESOLUTION_MINUTES', 4 * 60),
            ],
        ],
    ],
];
