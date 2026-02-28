<?php

return [
    'domain' => env('HORIZON_DOMAIN'),
    'path' => env('HORIZON_PATH', 'horizon'),
    'use' => 'default',
    'prefix' => env('HORIZON_PREFIX', 'mitabl_horizon:'),
    'middleware' => ['web'],
    'waits' => [
        'redis:default' => 60,
        'redis:crm-escalations' => 30,
        'redis:crm-communications' => 30,
    ],
    'trim' => [
        'recent' => 60,
        'pending' => 60,
        'completed' => 60,
        'recent_failed' => 10080,
        'failed' => 10080,
        'monitored' => 10080,
    ],
    'fast_termination' => false,
    'memory_limit' => 256,
    'defaults' => [
        'supervisor-1' => [
            'connection' => 'redis',
            'queue' => ['crm-escalations', 'crm-communications', 'default'],
            'balance' => 'auto',
            'maxProcesses' => 4,
            'maxTime' => 0,
            'maxJobs' => 0,
            'memory' => 256,
            'tries' => 3,
            'timeout' => 120,
            'nice' => 0,
        ],
    ],
    'environments' => [
        'production' => [
            'supervisor-1' => [
                'maxProcesses' => 10,
            ],
            'supervisor-crm-escalations' => [
                'connection' => 'redis',
                'queue' => ['crm-escalations'],
                'balance' => 'auto',
                'maxProcesses' => 4,
                'tries' => 3,
                'timeout' => 120,
            ],
            'supervisor-crm-communications' => [
                'connection' => 'redis',
                'queue' => ['crm-communications'],
                'balance' => 'auto',
                'maxProcesses' => 4,
                'tries' => 3,
                'timeout' => 120,
            ],
        ],
        'staging' => [
            'supervisor-1' => [
                'maxProcesses' => 6,
            ],
            'supervisor-crm-escalations' => [
                'connection' => 'redis',
                'queue' => ['crm-escalations'],
                'balance' => 'auto',
                'maxProcesses' => 3,
                'tries' => 3,
                'timeout' => 120,
            ],
            'supervisor-crm-communications' => [
                'connection' => 'redis',
                'queue' => ['crm-communications'],
                'balance' => 'auto',
                'maxProcesses' => 3,
                'tries' => 3,
                'timeout' => 120,
            ],
        ],
        'local' => [
            'supervisor-1' => [
                'maxProcesses' => 3,
            ],
        ],
    ],
];
