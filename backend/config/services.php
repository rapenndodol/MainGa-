<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Resend, Postmark, AWS, and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'postmark' => [
        'key' => env('POSTMARK_API_KEY'),
    ],

    'resend' => [
        'key' => env('RESEND_API_KEY'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'slack' => [
        'notifications' => [
            'bot_user_oauth_token' => env('SLACK_BOT_USER_OAUTH_TOKEN'),
            'channel' => env('SLACK_BOT_USER_DEFAULT_CHANNEL'),
        ],
    ],

    'rawg' => [
        'key' => env('RAWG_API_KEY'),
        'base_url' => env('RAWG_BASE_URL', 'https://api.rawg.io/api'),
        'timeout' => (int) env('RAWG_TIMEOUT', 10),
    ],

    'cheapshark' => [
        'base_url' => env('CHEAPSHARK_BASE_URL', 'https://www.cheapshark.com/api/1.0'),
        'timeout' => (int) env('CHEAPSHARK_TIMEOUT', 10),
        'user_agent' => env('CHEAPSHARK_USER_AGENT', 'MainGa/1.0 (support@mainga.app)'),
    ],

    'currency' => [
        'usd_to_idr_rate' => (float) env('USD_TO_IDR_RATE', 16000),
    ],

];
