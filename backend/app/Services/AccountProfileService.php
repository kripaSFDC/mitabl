<?php

namespace App\Services;

use App\Models\NotifyDisable;
use App\Models\StripeAccount;
use App\Models\User;
use App\Models\UserRole;
use App\Models\UserRoleOnboardingChecklist;
use Illuminate\Database\QueryException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Schema;
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

        $membership = $user->roleMembershipFor($targetRoleId);

        if (! $membership) {
            $membership = UserRole::query()->create([
                'user_id' => $user->id,
                'role_id' => $targetRoleId,
                'status' => $targetRoleId === 2
                    ? UserRole::STATUS_ONBOARDING
                    : UserRole::STATUS_ACTIVE,
            ]);
        }

        if ($membership->status === UserRole::STATUS_DISABLED) {
            return [
                'error' => 'Requested role is disabled for this account.',
                'status' => 422,
                'role_transition' => null,
            ];
        }

        if ($targetRoleId === 2) {
            $foodieMembership = $this->ensureRoleMembership($user->id, 3, UserRole::STATUS_ACTIVE);
            if ($foodieMembership->status === UserRole::STATUS_ONBOARDING) {
                $foodieMembership->status = UserRole::STATUS_ACTIVE;
                $foodieMembership->save();
            }

            // Every cook-capable account should also have a foodie persona ready.
            $this->ensureStripeAccountForRole($user, 3);
        }

        if ($targetRoleId === 3 && $membership->status !== UserRole::STATUS_ACTIVE) {
            $membership->status = UserRole::STATUS_ACTIVE;
            $membership->save();
            $membership->refresh();
        }

        if ($targetRoleId === 3) {
            // Foodie flows such as saved cards depend on a customer account.
            $this->ensureStripeAccountForRole($user, 3);
        }

        if ((int) $user->role_id !== $targetRoleId) {
            $user->role_id = $targetRoleId;
            $user->save();
        }

        $roleTransition = $this->buildRoleTransitionState($user, $targetRoleId, $membership);
        return [
            'user' => $user->fresh(['role', 'restaurant.certificate', 'notifyDisable', 'roleMemberships.role']),
            'role_transition' => $roleTransition,
            'onboarding_required' => (bool) ($roleTransition['onboarding_required'] ?? false),
        ];
    }

    public function startCookOnboarding(User $user): array
    {
        $membership = $user->roleMembershipFor(2);
        if (! $membership) {
            $membership = $this->ensureRoleMembership($user->id, 2, UserRole::STATUS_ONBOARDING);
        }

        if ($membership->status === UserRole::STATUS_DISABLED) {
            return [
                'error' => 'Requested role is disabled for this account.',
                'status' => 422,
                'role_transition' => null,
            ];
        }

        $this->ensureRoleMembership($user->id, 3, UserRole::STATUS_ACTIVE);
        $this->ensureStripeAccountForRole($user, 3);

        if ((int) $user->role_id === 3) {
            $user->role_id = 2;
            $user->save();
        }

        $transition = $this->buildRoleTransitionState($user, 2, $membership) ?? [
            'state' => 'ready',
            'missing' => [],
            'onboarding_required' => false,
            'next_required_step' => null,
            'checklist' => [],
        ];
        return [
            'user' => $user->fresh(['role', 'restaurant.certificate', 'notifyDisable', 'roleMemberships.role']),
            'role_transition' => $transition + [
                'onboarding_started' => true,
                'next_required_step' => $transition['missing'][0] ?? null,
            ],
            'onboarding_required' => (bool) ($transition['onboarding_required'] ?? false),
        ];
    }

    public function completeCookVendorAccountStep(User $user): array
    {
        $this->ensureRoleMembership($user->id, 2, UserRole::STATUS_ONBOARDING);

        $provisionError = $this->ensureStripeAccountForRole($user, 2);
        $membership = $user->roleMembershipFor(2);
        $transition = $this->buildRoleTransitionState($user, 2, $membership);

        return [
            'provisioned' => $provisionError === null,
            'provision_error' => $provisionError,
            'role_transition' => $transition,
            'onboarding_required' => (bool) ($transition['onboarding_required'] ?? false),
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

    private function buildRoleTransitionState(User $user, int $targetRoleId, ?UserRole $membership = null): ?array
    {
        if ($targetRoleId === 3) {
            return [
                'state' => 'ready',
                'missing' => [],
                'onboarding_required' => false,
                'next_required_step' => null,
                'checklist' => [
                    'foodie_profile' => true,
                ],
            ];
        }

        if ($targetRoleId !== 2) {
            return [
                'state' => 'ready',
                'missing' => [],
                'onboarding_required' => false,
                'next_required_step' => null,
                'checklist' => [],
            ];
        }

        $user->load(['restaurant.certificate', 'vendor']);

        $inferredChecklist = [
            'vendor_account' => (bool) ($user->vendor && $user->vendor->account_id),
            'kitchen_profile' => (bool) $user->restaurant,
            'certificate' => (bool) ($user->restaurant && $user->restaurant->certificate),
            'payout_setup' => (bool) ($user->vendor && $user->vendor->account_id),
        ];

        $effectiveChecklist = $inferredChecklist;

        if (Schema::hasTable('user_role_onboarding_checklists')) {
            $storedChecklist = UserRoleOnboardingChecklist::query()
                ->firstOrCreate(
                    ['user_id' => $user->id, 'role_id' => 2],
                    [
                        'vendor_account_completed' => false,
                        'kitchen_profile_completed' => false,
                        'certificate_completed' => false,
                        'payout_setup_completed' => false,
                    ]
                );

            $effectiveChecklist = [
                'vendor_account' => (bool) ($storedChecklist->vendor_account_completed || $inferredChecklist['vendor_account']),
                'kitchen_profile' => (bool) ($storedChecklist->kitchen_profile_completed || $inferredChecklist['kitchen_profile']),
                'certificate' => (bool) ($storedChecklist->certificate_completed || $inferredChecklist['certificate']),
                'payout_setup' => (bool) ($storedChecklist->payout_setup_completed || $inferredChecklist['payout_setup']),
            ];

            $storedChecklist->fill([
                'vendor_account_completed' => $effectiveChecklist['vendor_account'],
                'kitchen_profile_completed' => $effectiveChecklist['kitchen_profile'],
                'certificate_completed' => $effectiveChecklist['certificate'],
                'payout_setup_completed' => $effectiveChecklist['payout_setup'],
            ])->save();
        }

        $missing = collect($effectiveChecklist)
            ->filter(fn (bool $completed): bool => ! $completed)
            ->keys()
            ->values()
            ->all();

        $membership = $membership ?? $user->roleMembershipFor($targetRoleId);

        if ($membership && $targetRoleId === 2 && $membership->status !== UserRole::STATUS_DISABLED) {
            $desiredStatus = count($missing) === 0
                ? UserRole::STATUS_ACTIVE
                : UserRole::STATUS_ONBOARDING;

            if ($membership->status !== $desiredStatus) {
                $membership->status = $desiredStatus;
                $membership->save();
            }

            $membership->refresh();
        }

        $onboardingRequired = count($missing) > 0 || ($membership && $membership->status === UserRole::STATUS_ONBOARDING);

        return [
            'state' => $onboardingRequired ? 'onboarding_required' : 'ready',
            'missing' => $missing,
            'onboarding_required' => $onboardingRequired,
            'next_required_step' => $missing[0] ?? null,
            'checklist' => $effectiveChecklist,
        ];
    }

    private function ensureRoleMembership(int $userId, int $roleId, string $status): UserRole
    {
        return UserRole::query()->firstOrCreate(
            ['user_id' => $userId, 'role_id' => $roleId],
            ['status' => $status],
        );
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
