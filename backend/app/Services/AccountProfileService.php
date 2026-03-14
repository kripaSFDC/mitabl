<?php

namespace App\Services;

use App\Models\NotifyDisable;
use App\Models\StripeAccount;
use App\Models\User;
use Illuminate\Database\QueryException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Throwable;

class AccountProfileService
{
    public function __construct(private PaymentService $paymentService)
    {
    }

    public function updateProfile(User $user, Request $request, callable $uploadImage): array
    {
        $validator = Validator::make($request->all(), [
            'first_name' => 'required|string|max:100',
            'last_name' => 'required|string|max:100',
            'phone' => 'required|string|max:30',
            'email' => 'required|email|unique:users,email,' . $user->id,
        ]);

        if ($validator->fails()) {
            return ['error' => $validator->errors()->first(), 'status' => 422];
        }

        $user->first_name = (string) $request->first_name;
        $user->last_name = (string) $request->last_name;
        $user->email = (string) $request->email;
        $user->phone = (string) $request->phone;
        $user->description = $request->description;

        if ($request->hasFile('avatar')) {
            $avatar = $uploadImage($request->avatar, 'user');
            if (! ($avatar['success'] ?? false)) {
                return ['error' => (string) ($avatar['msg'] ?? 'Unable to upload avatar.'), 'status' => 422];
            }
            $user->avatar = (string) $avatar['path'];
        }

        $user->save();

        return ['user' => $user];
    }

    public function switchRole(User $user, Request $request): array
    {
        $validator = Validator::make($request->all(), [
            'role_id' => 'required|integer|in:2,3',
        ]);

        if ($validator->fails()) {
            return ['error' => $validator->errors()->first(), 'status' => 422];
        }

        $targetRoleId = (int) $request->input('role_id');
        if ((int) $user->role_id === $targetRoleId) {
            return [
                'user' => $user->fresh(['role', 'restaurant.certificate', 'notifyDisable']),
                'role_transition' => $this->buildRoleTransitionState($user, $targetRoleId),
            ];
        }

        if ($targetRoleId === 2) {
            $provisionError = $this->ensureStripeAccountForRole($user, 2);
            if ($provisionError !== null) {
                return ['error' => $provisionError, 'status' => 422];
            }
        }

        $user->role_id = $targetRoleId;
        $user->save();

        return [
            'user' => $user->fresh(['role', 'restaurant.certificate', 'notifyDisable']),
            'role_transition' => $this->buildRoleTransitionState($user, $targetRoleId),
        ];
    }

    public function startCookOnboarding(User $user): array
    {
        $provisionError = $this->ensureStripeAccountForRole($user, 2);
        if ($provisionError !== null) {
            return ['error' => $provisionError, 'status' => 422];
        }

        if ((int) $user->role_id === 3) {
            $user->role_id = 2;
            $user->save();
        }

        $transition = $this->buildRoleTransitionState($user, 2) ?? ['state' => 'ready', 'missing' => []];

        return [
            'user' => $user->fresh(['role', 'restaurant.certificate', 'notifyDisable']),
            'role_transition' => $transition + [
                'onboarding_started' => true,
                'next_required_step' => $transition['missing'][0] ?? null,
            ],
        ];
    }

    public function ensureStripeAccountForRole(User $user, ?int $roleId = null): ?string
    {
        $targetRoleId = $roleId ?? (int) $user->role_id;
        $accountType = null;
        if ($targetRoleId === 3) {
            $accountType = 'customer';
        } elseif ($targetRoleId === 2) {
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

                if ($locked) {
                    $locked->account_id = (string) $account->id;
                    $locked->save();
                    return;
                }

                $stripeAccount = new StripeAccount();
                $stripeAccount->user_id = $user->id;
                $stripeAccount->account_type = $accountType;
                $stripeAccount->account_id = (string) $account->id;
                $stripeAccount->save();
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

    private function buildRoleTransitionState(User $user, int $targetRoleId): ?array
    {
        if ($targetRoleId !== 2) {
            return null;
        }

        $user->loadMissing('restaurant.certificate', 'vendor');

        $missing = [];
        if (! $user->vendor || ! $user->vendor->account_id) {
            $missing[] = 'vendor_account';
        }
        if (! $user->restaurant) {
            $missing[] = 'kitchen_profile';
            $missing[] = 'certificate';
        } elseif (! $user->restaurant->certificate) {
            $missing[] = 'certificate';
        }

        return [
            'state' => count($missing) > 0 ? 'onboarding_required' : 'ready',
            'missing' => $missing,
        ];
    }

    public function changePassword(User $user, Request $request): array
    {
        $validator = Validator::make($request->all(), [
            'current_password' => 'required',
            'new_password' => 'required|different:current_password|min:6',
        ]);
        if ($validator->fails()) {
            return ['error' => $validator->errors()->first(), 'status' => 422];
        }

        if (! Hash::check((string) $request->current_password, (string) $user->password)) {
            return ['error' => 'Current password doesn\'t match', 'status' => 422];
        }

        $user->password = bcrypt((string) $request->new_password);
        $user->save();

        return ['updated' => true];
    }

    public function updateDeviceToken(User $user, Request $request): array
    {
        $validator = Validator::make($request->all(), [
            'device_token' => 'required|string|max:2048',
        ]);
        if ($validator->fails()) {
            return ['error' => $validator->errors()->first(), 'status' => 422];
        }

        $user->device_token = (string) $request->device_token;
        $user->save();

        return ['updated' => true];
    }

    public function toggleNotifications(User $user): array
    {
        $existing = NotifyDisable::where('user_id', $user->id)->first();
        if ($existing) {
            $existing->delete();
        } else {
            $notifyDisable = new NotifyDisable();
            $notifyDisable->user_id = $user->id;
            $notifyDisable->save();
        }

        return ['updated' => true];
    }

    public function updateNotificationPreferences(User $user, Request $request): array
    {
        $validator = Validator::make($request->all(), [
            'notifications_enabled' => 'nullable|boolean',
            'device_key' => 'nullable|string|max:2048',
            'device_token' => 'nullable|string|max:2048',
        ]);

        if ($validator->fails()) {
            return ['error' => $validator->errors()->first(), 'status' => 422];
        }

        $deviceToken = $request->input('device_key', $request->input('device_token'));
        if (is_string($deviceToken) && trim($deviceToken) !== '') {
            $user->device_token = trim($deviceToken);
        }

        if ($request->has('notifications_enabled')) {
            $enabled = filter_var($request->input('notifications_enabled'), FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_FAILURE);
            if ($enabled === null) {
                return ['error' => 'notifications_enabled must be a boolean value.', 'status' => 422];
            }

            if ($enabled) {
                NotifyDisable::where('user_id', $user->id)->delete();
            } else {
                $existing = NotifyDisable::where('user_id', $user->id)->first();
                if (! $existing) {
                    $notifyDisable = new NotifyDisable();
                    $notifyDisable->user_id = $user->id;
                    $notifyDisable->save();
                }
            }
        }

        if ($user->isDirty('device_token')) {
            $user->save();
        }

        return [
            'updated' => true,
            'notifications_enabled' => ! (bool) $user->notifyDisable,
            'has_device_token' => ! empty($user->device_token),
        ];
    }

    public function mobileContact(User $user): array
    {
        $user->loadMissing(['role', 'notifyDisable']);

        return [
            'id' => (int) $user->id,
            'name' => trim((string) ($user->first_name . ' ' . $user->last_name)),
            'email' => (string) $user->email,
            'phone' => (string) ($user->phone ?? ''),
            'role_id' => (int) $user->role_id,
            'role' => (string) optional($user->role)->name,
            'notifications_enabled' => ! (bool) $user->notifyDisable,
            'has_device_token' => ! empty($user->device_token),
        ];
    }
}
