<?php

namespace App\Http\Controllers\Api\User\Concerns;

use App\Models\Mikitchn;
use App\Models\StripeAccount;
use App\Models\User;
use App\Models\UserAuthToken;
use App\Models\verifyOtp;
use Illuminate\Database\QueryException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Throwable;
use Tymon\JWTAuth\Exceptions\JWTException;
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

        try {
            if (! $token = auth()->attempt($credentials)) {
                return $this->responser([], 'Login credentials are invalid.', 401);
            }
        } catch (JWTException $e) {
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

        if ($user->email_verified == 1) {
            if (! $this->hasStripeAccountForRole($user)) {
                $stripeProvisionError = $this->ensureStripeAccountForRole($user);
                if ($stripeProvisionError !== null) {
                    $user->email_verified = 0;
                    $user->save();
                    $this->sendOtp($user->id, $user->email);

                    Auth::guard('api')->logout();
                    return $this->responser(
                        [],
                        'Your account verification needs to be retried. A new OTP has been sent to your email.',
                        422
                    );
                }
            }

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

            $uData = [
                'id' => $user->id,
                'name' => $user->first_name,
                'role' => $user->role->role,
                'role_id' => $user->role_id,
            ];

            if ((int) $user->role_id === 2) {
                $uData['is_kitchen_added'] = $this->resolveKitchenAddedFlag($user);
            }

            return $this->responser([
                'access_token' => $token,
                'token_type' => 'bearer',
                'user' => $uData,
            ], '');
        }

        $responseOtp = $this->sendOtp($user->id, $user->email);
        $msg = $responseOtp['status'] == 200
            ? 'UnAuthorized Please Check Your Email To Verify Your Account.'
            : 'UnAuthorized.';

        $uData = [
            'id' => $user->id,
            'name' => $user->first_name,
            'role' => $user->role->role,
            'role_id' => $user->role_id,
            'is_email_verfied' => 0,
        ];

        if ((int) $user->role_id === 2) {
            $uData['is_kitchen_added'] = $this->resolveKitchenAddedFlag($user);
        }

        return $this->responser(['user' => $uData], $msg);
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
            'phone' => 'required|numeric',
        ]);

        if ($validator->fails()) {
            return $this->responser([], $validator->errors()->first(), 422);
        }

        $roleId = $request->filled('role_id') ? (int) $request->input('role_id') : 3;

        $input = [
            'first_name' => (string) $request->input('first_name'),
            'last_name' => (string) $request->input('last_name'),
            'email' => (string) $request->input('email'),
            'password' => (string) $request->input('password'),
            'phone' => (string) $request->input('phone'),
            'address' => (string) $request->input('address', ''),
            'role_id' => $roleId,
        ];

        $input['password'] = bcrypt($input['password']);
        $user = User::create($input);

        if ($request->has('device_token')) {
            $user->device_token = $request->device_token;
        }
        $user->save();

        $userData = [
            'id' => $user->id,
            'name' => $user->first_name . ' ' . $user->last_name,
            'email' => $user->email,
            'role_id' => $user->role_id,
            'role' => $user->role->role,
        ];

        $this->sendOtp($user->id, $user->email);

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
                $lockThreshold = 5;
                $lockMinutes = 15;
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
                    'role' => $user->role->role,
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

        $stripeProvisionError = $this->ensureStripeAccountForRole($verifiedUser);
        if ($stripeProvisionError !== null) {
            $this->sendOtp($verifiedUser->id, $verifiedUser->email);
            return $this->responser([], 'Unable to create Stripe account. A new OTP has been sent, please verify again.', 422);
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

    public function becomeFoodie(Request $request)
    {
        $authUser = Auth::guard('api')->user();
        $accessToken = request()->bearerToken();

        $result = DB::transaction(function () use ($authUser) {
            $user = User::whereKey($authUser->id)->lockForUpdate()->firstOrFail();
            $user->role_id = 3;
            $user->save();

            return ['user' => $user->fresh()];
        });
        $user = $result['user'];

        $stripeProvisionError = $this->ensureStripeAccountForRole($user);
        if ($stripeProvisionError !== null) {
            return $this->responser([], (string) $stripeProvisionError, 422);
        }

        $data = [
            'access_token' => $accessToken,
            'token_type' => 'bearer',
            'user' => [
                'id' => $user->id,
                'name' => $user->first_name,
                'role' => $user->role->role,
                'role_id' => $user->role_id,
            ],
        ];

        return $this->responser($data, 'User Now changed in foodie');
    }

    public function becomeCook(Request $request)
    {
        $authUser = Auth::guard('api')->user();
        $accessToken = request()->bearerToken();

        $result = DB::transaction(function () use ($authUser) {
            $user = User::whereKey($authUser->id)->lockForUpdate()->firstOrFail();
            $user->role_id = 2;
            $user->save();

            return ['user' => $user->fresh()];
        });
        $user = $result['user'];

        $stripeProvisionError = $this->ensureStripeAccountForRole($user);
        if ($stripeProvisionError !== null) {
            return $this->responser([], (string) $stripeProvisionError, 422);
        }

        $isKitchen = $this->resolveKitchenAddedFlag($user);

        $data = [
            'access_token' => $accessToken,
            'token_type' => 'bearer',
            'user' => [
                'id' => $user->id,
                'name' => $user->first_name,
                'role' => $user->role->role,
                'role_id' => $user->role_id,
                'is_kitchen_added' => $isKitchen,
            ],
        ];

        return $this->responser($data, 'User Now changed in cook');
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

    private function ensureStripeAccountForRole(User $user): ?string
    {
        $accountType = null;
        if ((int) $user->role_id === 3) {
            $accountType = 'customer';
        } elseif ((int) $user->role_id === 2) {
            $accountType = 'vendor';
        }

        if ($accountType === null) {
            return 'Unsupported account role for payment account provisioning.';
        }

        $existing = StripeAccount::query()
            ->where('user_id', $user->id)
            ->where('account_type', $accountType)
            ->first();
        if ($existing && $existing->account_id) {
            return null;
        }

        try {
            if ($accountType === 'customer') {
                $account = $this->paymentService->createCustomer(['name' => $user->first_name, 'email' => $user->email]);
            } else {
                $account = $this->paymentService->createVendor($user);
            }
        } catch (Throwable $throwable) {
            report($throwable);
            return 'Unable to create Stripe account.';
        }
        if (! is_object($account) || ! isset($account->id)) {
            return 'Unable to create Stripe account.';
        }

        try {
            DB::transaction(function () use ($user, $accountType, $account): void {
                $locked = StripeAccount::query()
                    ->where('user_id', $user->id)
                    ->where('account_type', $accountType)
                    ->lockForUpdate()
                    ->first();
                if ($locked && $locked->account_id) {
                    return;
                }

                StripeAccount::query()->updateOrCreate(
                    ['user_id' => $user->id, 'account_type' => $accountType],
                    ['account_id' => (string) $account->id]
                );
            });
        } catch (QueryException $exception) {
            report($exception);
            $existing = StripeAccount::query()
                ->where('user_id', $user->id)
                ->where('account_type', $accountType)
                ->first();
            if (! $existing || ! $existing->account_id) {
                return 'Unable to create Stripe account.';
            }
        }

        return null;
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
