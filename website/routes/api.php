<?php

use Illuminate\Support\Facades\Route;

Route::fallback(function () {
    return response()->json([
        'status' => 404,
        'isSuccess' => false,
        'message' => 'No public website API endpoints are available.',
        'data' => [],
    ], 404);
});
