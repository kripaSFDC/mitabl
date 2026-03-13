<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;

/**
 * Returns the current minimum and latest version constraints for the mobile app.
 *
 * The mobile app calls this endpoint during its splash screen to decide whether
 * to prompt the user to update (optional) or force an upgrade (required).
 *
 * To gate a new mandatory version:
 *   1. Bump `APP_VERSION_MINIMUM` in your .env (and production config).
 * To advertise a new optional update:
 *   2. Bump `APP_VERSION_LATEST`.
 *
 * No database — just environment/config values so ops can roll this out
 * without a deploy.
 */
class AppVersionController extends Controller
{
    public function show()
    {
        return response()->json([
            'minimum'     => config('app.version_minimum', '1.0.0'),
            'latest'      => config('app.version_latest',  '1.0.0'),
            'ios_url'     => config('app.version_ios_url',     'https://apps.apple.com/app/mitabl/id0000000000'),
            'android_url' => config('app.version_android_url', 'https://play.google.com/store/apps/details?id=com.mitabl.user.mitabl_user'),
        ]);
    }
}
