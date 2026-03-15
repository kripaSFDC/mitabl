<?php

namespace App\Http\Controllers\Api\User\Concerns;

use App\Models\Mikitchn;
use App\Models\User;
use App\Models\UserAuthToken;
use App\Models\UserRole;
use App\Models\verifyOtp;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Throwable;
use Tymon\JWTAuth\Exceptions\JWTException;
use Tymon\JWTAuth\Exceptions\TokenBlacklistedException;
use Tymon\JWTAuth\Exceptions\TokenExpiredException;
use Tymon\JWTAuth\Exceptions\TokenInvalidException;
use Validator;
use JWTAuth;

trait HandlesUserAuthentication
{
    public function login(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email',
            'password' => 'required|string|min:6',
        ]);
        if ($validator->fails()) {
            return $this->responser([], $validator->errors()->first(), 422);
        }

        $credentials = $request->only('email', 'password');

        $jwtSecret = trim((string) config('jwt.secret', ''));
        if ($jwtSecret === '') {
            report(new JWTException('JWT secret is not configured.'));
            return $this->responser([], 'Authentication service is not configured. Please contact support.', 503);
        }

        try {
            if (! $token = auth()->attempt($credentials)) {
                return $this->responser([], 'Login credentials are invalid.', 401);
            }
        } catch (JWTException $e) {
            report($e);
            return $this->responser([], 'Could not create token.', 500);
        }

        $user = Auth::guard('api')->user();

        if (! $user) {
            return $this->responser([], 'Unable to resolve authenticated user.', 401);
        }

        if ($this->isAdminIdentityRole((int) $user->role_id)) {
            Auth::guard('api')->logout();
            return $this->forbiddenAdminIdentityResponse();
        }

        if ((bool) $user->suspended) {
            Auth::guard('api')->logout();
            return $this->suspendedAccountResponse();
        }

        if (! in_array((int) $user->role_id, [2, 3], true)) {
            Auth::guard('api')->logout();
            return $this->responser([], 'Unsupported account role for mobile authentication.', 422);
        }

        $this->ensureActiveRoleMembership($user);

        if (! $this->canUseActiveRole($user)) {
            Auth::guard('api')->logout();
            return $this->disabledRoleResponse();
        }

        $roleName = $this->resolveMobileRoleName($user);
        if ($roleName === null) {
            Auth::guard('api')->logout();
            report(new \RuntimeException('User role mapping is missing for user id ' . (string) $user->id));
            return $this->responser([], 'Account role is not configured. Please contact support.', 422);
        }

        if ($user->email_verified == 1) {

            $previousToken = (string) optional($user->Token)->latest_token;
            if ($previousToken !== '') {
                try {
                    JWTAuth::setToken($previousToken);
                    JWTAuth::invalidate();
                } catch (Throwable $throwable) {
                    report($throwable);
                }
            }

            UserAuthToken::query()->updateOrCreate(
                ['user_id' => $user->id],
                ['latest_token' => $token]
            );

            if ($request->has('device_token')) {
                $user->device_token = $request->device_token;
            }
            $user->save();

            $uData = $this->buildVerifiedMobileUserPayload($user);

            return $this->responser([
                'access_token' => $token,
                'token_type' => 'bearer',
                'user' => $uData,
            ], 'Login successful.');
        }

        $responseOtp = $this->sendOtp($user->id, $user->email);
        $msg = $responseOtp['status'] == 200
            ? 'UnAuthorized Please Check Your Email To Verify Your Account.'
            : 'UnAuthorized.';

        $uData = $this->buildVerifiedMobileUserPayload($user);
        $uData['is_email_verfied'] = 0;

        return $this->responser(['user' => $uData], $msg);
    }

    /**
     * @OA\Post(
     * path="/api/token/refresh",
     * summary="Refresh mobile access token",
     * description="Returns a replacement bearer JWT when the presented token is still within the backend refresh TTL window.",
     * operationId="token-refresh",
     * tags={"User"},
     * security={{"Authorization":{}}},
     * @OA\Response(
     *   response=200,
     *   description="Token refreshed successfully",
     *   @OA\JsonContent()
     * ),
     * @OA\Response(
     *   response=401,
     *   description="Refresh token missing, malformed, invalid, expired, or blacklisted",
     *   @OA\JsonContent()
     * ),
     * @OA\Response(response=403, description="Suspended or forbidden account role")
     * )
     */
    public function refreshToken(Request $request)
    {
        try {
            $newToken = JWTAuth::parseToken()->refresh();
            $user = JWTAuth::setToken($newToken)->authenticate();
            if (! $user) {
                return $this->responser([], 'Unable to resolve authenticated user.', 401);
            }

            if ($this->isAdminIdentityRole((int) $user->role_id)) {
                $this->invalidateTokenQuietly($newToken);
                return $this->forbiddenAdminIdentityResponse();
            }

            if ((bool) $user->suspended) {
                $this->invalidateTokenQuietly($newToken);
                return $this->suspendedAccountResponse();
            }

            $this->ensureActiveRoleMembership($user);
            if (! $this->canUseActiveRole($user)) {
                $this->invalidateTokenQuietly($newToken);
                return $this->disabledRoleResponse();
            }

            UserAuthToken::query()->updateOrCreate(
                ['user_id' => $user->id],
                ['latest_token' => $newToken]
            );

            return $this->responser([
                'access_token' => $newToken,
                'token_type' => 'bearer',
                'expires_in_minutes' => config('jwt.ttl'),
                'refresh_expires_in_minutes' => config('jwt.refresh_ttl'),
                'user' => $this->buildVerifiedMobileUserPayload($user),
            ], 'Token refreshed successfully.');
        } catch (TokenExpiredException|TokenInvalidException|TokenBlacklistedException $exception) {
            return $this->responser([], 'Refresh token is invalid or expired. Please login again.', 401);
        } catch (JWTException $exception) {
            return $this->responser([], 'Refresh token is missing or malformed.', 401);
        }
    }

    public function register(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'first_name' => 'required|string|max:100',
            'last_name' => 'required|string|max:100',
            'email' => 'required|email|unique:users,email',
            'password' => 'required|string|min:6',
            'password_confirmation' => 'nullable|string|same:password',
            'role_id' => 'nullable|integer|in:2,3',
            'phone' => ['required', 'string', 'max:20', 'regex:/^\+[1-9]\d{6,14}$/'],
        ]);

        if ($validator->fails()) {
            return $this->responser([], $validator->errors()->first(), 422);
        }

        $roleId = $request->filled('role_id') ? (int) $request->input('role_id') : 3;

        $normalizedPhone = $this->normalizeInternationalPhone((string) $request->input('phone'));
        if ($normalizedPhone === null) {
            return $this->responser([], 'Please provide a valid international phone number.', 422);
        }

        $input = [
            'first_name' => (string) $request->input('first_name'),
            'last_name' => (string) $request->input('last_name'),
            'email' => (string) $request->input('email'),
            'password' => (string) $request->input('password'),
            'phone' => $normalizedPhone,
            'address' => (string) $request->input('address', ''),
            'role_id' => $roleId,
        ];

        $input['password'] = bcrypt($input['password']);
        $user = User::create($input);

        UserRole::query()->firstOrCreate(
            ['user_id' => $user->id, 'role_id' => (int) $user->role_id],
            ['status' => UserRole::STATUS_ACTIVE]
        );

        if ($request->has('device_token')) {
            $user->device_token = $request->device_token;
        }
        $user->save();

        $userData = [
            'id' => $user->id,
            'name' => $user->first_name . ' ' . $user->last_name,
            'email' => $user->email,
            'role_id' => $user->role_id,
            'role' => $this->resolveMobileRoleName($user) ?? 'Unknown',
        ];

        $otpResponse = $this->sendOtp($user->id, $user->email);
        if (($otpResponse['status'] ?? 500) !== 200) {
            return $this->responser(
                [
                    'user_id' => $user->id,
                    'otp_dispatched' => false,
                ],
                (string) ($otpResponse['message'] ?? 'Unable to send OTP at this time.'),
                503
            );
        }

        return $this->responser($userData, 'Registered Successfully.');
    }

    public function resendOtp(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'user_id' => 'required|integer|exists:users,id',
        ]);

        if ($validator->fails()) {
            return $this->responser([], $validator->errors()->first(), 422);
        }

        $user = User::find($request->user_id);

        if ($user) {
            $otpres = $this->sendOtp($user->id, $user->email);
            if ($otpres['status'] == 200) {
                $rsend = 1;
                $msg = 'Send Otp Successfully';
            } else {
                $msg = 'UnAuthorized.';
                $rsend = 0;
            }

            return $this->responser(['resend' => $rsend], $msg);
        }

        return $this->responser([], 'User not found', 404);
    }

    public function sendOtp($id, $userEmail)
    {
        return $this->authService->sendOtp((int) $id, (string) $userEmail);
    }

    private function normalizeInternationalPhone(string $value): ?string
    {
        $trimmed = trim($value);
        if ($trimmed === '') {
            return null;
        }

        $normalized = preg_replace('/[^\d+]/', '', $trimmed) ?? '';
        if (! str_starts_with($normalized, '+')) {
            return null;
        }

        $digits = preg_replace('/\D+/', '', $normalized) ?? '';
        if ($digits === '' || preg_match('/^[1-9]\d{6,14}$/', $digits) !== 1) {
            return null;
        }

        return '+' . $digits;
    }

    public function verifyOtp(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'id' => 'required|integer|exists:users,id',
            'otp' => 'required|digits:6',
        ]);

        if ($validator->fails()) {
            return $this->responser([], $validator->errors()->first(), 422);
        }

        $verifiedUserId = null;
        $response = DB::transaction(function () use ($request, &$verifiedUserId) {
            $otpRecord = verifyOtp::where('user_id', (int) $request->id)->lockForUpdate()->first();
            if (! $otpRecord) {
                return $this->responser([], 'Invalid Otp.', 401);
            }

            if ($otpRecord->locked_until && $otpRecord->locked_until->isFuture()) {
                return $this->responser([], 'Too many attempts. Try again later.', 429);
            }

            if ($otpRecord->expires_at && $otpRecord->expires_at->isPast()) {
                return $this->responser([], 'OTP expired. Please request a new code.', 422);
            }

            $providedOtp = (string) $request->otp;
            $otpMatched = $this->otpMatches($otpRecord, $providedOtp);

            if (! $otpMatched) {
                $attempts = ((int) $otpRecord->attempts) + 1;
                $lockThreshold = max(1, (int) config('auth.otp.max_attempts', 5));
                $lockMinutes = max(1, (int) config('auth.otp.lock_minutes', 15));
                $otpRecord->attempts = $attempts;
                if ($attempts >= $lockThreshold) {
                    $otpRecord->locked_until = now()->addMinutes($lockMinutes);
                    $otpRecord->attempts = 0;
                }
                $otpRecord->save();

                return $this->responser([], 'Invalid Otp.', 401);
            }

            $user = User::where('id', (int) $request->id)->lockForUpdate()->first();
            if (! $user) {
                return $this->responser([], 'User not found.', 404);
            }

            if ($this->isAdminIdentityRole((int) $user->role_id)) {
                return $this->forbiddenAdminIdentityResponse();
            }

            if (! in_array((int) $user->role_id, [2, 3], true)) {
                return $this->responser([], 'Unsupported account role for mobile authentication.', 422);
            }

            if ((bool) $user->suspended) {
                return $this->suspendedAccountResponse();
            }

            $verifiedUserId = (int) $user->id;

            return $this->responser([
                'user' => [
                    'id' => $user->id,
                    'name' => $user->first_name . ' ' . $user->last_name,
                    'email' => $user->email,
                    'role' => $this->resolveMobileRoleName($user) ?? 'Unknown',
                ],
            ], 'OTP Verified');
        });

        if ($verifiedUserId === null || $response->getStatusCode() !== 200) {
            return $response;
        }

        $verifiedUser = User::query()->find($verifiedUserId);
        if (! $verifiedUser) {
            return $this->responser([], 'User not found.', 404);
        }

        DB::transaction(function () use ($verifiedUser): void {
            $user = User::query()->whereKey($verifiedUser->id)->lockForUpdate()->firstOrFail();
            $user->email_verified = 1;
            $user->save();

            verifyOtp::query()->where('user_id', $user->id)->delete();
        });

        $accessToken = auth()->login($verifiedUser, true);
        if ($accessToken) {
            UserAuthToken::query()->updateOrCreate(
                ['user_id' => $verifiedUser->id],
                ['latest_token' => $accessToken]
            );
        }

        $decoded = $response->getData(true);
        $decoded['data']['access_token'] = $accessToken;

        return $this->responser($decoded['data'] ?? [], (string) ($decoded['message'] ?? ''), 200);
    }

    public function logout(Request $request)
    {
        $data = Auth::guard('api')->user();
        Auth::guard('api')->logout();

        return $this->responser($data, 'User logged out.');
    }

    public function delete(Request $request)
    {
        $user = Auth::guard('api')->user();
        $userId = (int) $user->id;

        UserAuthToken::query()->where('user_id', $userId)->delete();
        Auth::guard('api')->logout();
        $user->delete();

        return $this->responser([
            'id' => $userId,
            'deleted' => true,
        ], 'Account Deleted Successfully.');
    }

    private function isAdminIdentityRole(int $roleId): bool
    {
        return $roleId === 1;
    }

    private function forbiddenAdminIdentityResponse(): JsonResponse
    {
        return $this->responser([], 'Forbidden. Admin identities must authenticate via the web admin panel.', 403);
    }

    private function suspendedAccountResponse(): JsonResponse
    {
        return $this->responser([], 'Your account is suspended. Please contact support.', 403);
    }

    private function disabledRoleResponse(): JsonResponse
    {
        return $this->responser([], 'Your selected role is disabled. Please contact support.', 403);
    }

    private function canUseActiveRole(User $user): bool
    {
        $membership = $user->roleMembershipFor((int) $user->role_id);

        if (! $membership) {
            return true;
        }

        return $membership->status !== UserRole::STATUS_DISABLED;
    }

    private function ensureStripeAccountForRole(User $user): ?string
    {
        return $this->accountProfileService->ensureStripeAccountForRole($user, (int) $user->role_id);
    }

    private function hasStripeAccountForRole(User $user): bool
    {
        if ((int) $user->role_id === 3) {
            return (bool) optional($user->customer)->account_id;
        }

        if ((int) $user->role_id === 2) {
            return (bool) optional($user->vendor)->account_id;
        }

        return false;
    }

    private function resolveKitchenAddedFlag(User $user): int
    {
        return Mikitchn::query()->where('user_id', $user->id)->exists() ? 1 : 0;
    }

    private function buildVerifiedMobileUserPayload(User $user): array
    {
        $this->ensureActiveRoleMembership($user);
        $roleName = $this->resolveMobileRoleName($user) ?? 'Unknown';

        $memberships = $user->roleMemberships()->with('role')->get();
        $availableRoles = $memberships->map(function (UserRole $membership): array {
            return [
                'role_id' => (int) $membership->role_id,
                'role' => optional($membership->role)->role,
                'status' => $membership->status,
                'onboarding' => $membership->status === UserRole::STATUS_ONBOARDING,
            ];
        })->values();

        $data = [
            'id' => $user->id,
            'name' => $user->first_name,
            'role' => $roleName,
            'role_id' => $user->role_id,
            'active_role_id' => (int) $user->role_id,
            'available_roles' => $availableRoles,
        ];

        if ((int) $user->role_id === 2) {
            $data['is_kitchen_added'] = $this->resolveKitchenAddedFlag($user);
        }

        return $data;
    }


    private function ensureActiveRoleMembership(User $user): void
    {
        UserRole::query()->firstOrCreate(
            ['user_id' => $user->id, 'role_id' => (int) $user->role_id],
            ['status' => UserRole::STATUS_ACTIVE]
        );
    }

    private function resolveMobileRoleName(User $user): ?string
    {
        $fromRelation = optional($user->role)->role;
        if (is_string($fromRelation) && trim($fromRelation) !== '') {
            return $fromRelation;
        }

        return match ((int) $user->role_id) {
            1 => 'Admin',
            2 => 'Restaurant',
            3 => 'Foodie',
            default => null,
        };
    }

    private function invalidateTokenQuietly(string $token): void
    {
        try {
            JWTAuth::setToken($token);
            JWTAuth::invalidate();
        } catch (Throwable $throwable) {
            report($throwable);
        }
    }

    private function otpMatches(verifyOtp $otpRecord, string $providedOtp): bool
    {
        $storedOtp = (string) $otpRecord->otp;
        $hashInfo = Hash::info($storedOtp);
        $isHashed = ($hashInfo['algo'] ?? null) !== null;

        if ($isHashed) {
            return Hash::check($providedOtp, $storedOtp);
        }

        if (! hash_equals($storedOtp, $providedOtp)) {
            return false;
        }

        // Legacy plaintext OTP support: migrate to hash on successful match.
        $otpRecord->otp = Hash::make($providedOtp);
        $otpRecord->save();

        return true;
    }
}
