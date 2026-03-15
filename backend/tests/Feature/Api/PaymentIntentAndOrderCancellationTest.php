<?php

namespace Tests\Feature\Api;

use App\Models\Mikitchn;
use App\Models\Order;
use App\Models\User;
use App\Models\UserRole;
use App\Services\AccountProfileService;
use App\Services\PaymentService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Queue;
use Mockery;
use Tests\TestCase;

class PaymentIntentAndOrderCancellationTest extends TestCase
{
    use RefreshDatabase;

    public function test_create_intent_persists_selected_saved_card_for_order(): void
    {
        [$foodie, $cook, $order] = $this->createOrderFixture();

        DB::table('stripe_accounts')->insert([
            'user_id' => $foodie->id,
            'account_type' => 'customer',
            'account_id' => 'cus_fixture_123',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $paymentService = Mockery::mock(PaymentService::class);
        $paymentService->shouldReceive('initializeOrderPaymentIntent')
            ->once()
            ->withArgs(function (Order $passedOrder, User $passedUser, ?string $cardReference, ?string $paymentMethodId) use ($order, $foodie): bool {
                return (int) $passedOrder->id === (int) $order->id
                    && (int) $passedUser->id === (int) $foodie->id
                    && $cardReference === '15'
                    && $paymentMethodId === null;
            })
            ->andReturn([
                'payment' => new \App\Models\Payment([
                    'id' => 1,
                    'payment_id' => 'pi_saved_123',
                    'card_id' => 'pm_saved_123',
                    'status' => 'requires_confirmation',
                ]),
                'selection' => [
                    'payment_method_id' => 'pm_saved_123',
                    'customer_id' => 'cus_fixture_123',
                    'mode' => 'saved_card',
                ],
            ]);
        $this->app->instance(PaymentService::class, $paymentService);

        $this->actingAs($foodie, 'api');

        $this->postJson('/api/v2/payments/intent', [
            'order_id' => $order->id,
            'card_id' => '15',
        ])
            ->assertOk()
            ->assertJsonPath('data.payment_intent_id', 'pi_saved_123')
            ->assertJsonPath('data.payment_method_id', 'pm_saved_123')
            ->assertJsonPath('data.selection_mode', 'saved_card');
    }

    public function test_create_intent_accepts_one_time_payment_method_reference(): void
    {
        [$foodie, $cook, $order] = $this->createOrderFixture();

        DB::table('stripe_accounts')->insert([
            'user_id' => $foodie->id,
            'account_type' => 'customer',
            'account_id' => 'cus_fixture_456',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $paymentService = Mockery::mock(PaymentService::class);
        $paymentService->shouldReceive('initializeOrderPaymentIntent')
            ->once()
            ->withArgs(function (Order $passedOrder, User $passedUser, ?string $cardReference, ?string $paymentMethodId) use ($order, $foodie): bool {
                return (int) $passedOrder->id === (int) $order->id
                    && (int) $passedUser->id === (int) $foodie->id
                    && $cardReference === null
                    && $paymentMethodId === 'pm_one_time_123';
            })
            ->andReturn([
                'payment' => new \App\Models\Payment([
                    'id' => 1,
                    'payment_id' => 'pi_one_time_123',
                    'card_id' => 'pm_one_time_123',
                    'status' => 'requires_confirmation',
                ]),
                'selection' => [
                    'payment_method_id' => 'pm_one_time_123',
                    'customer_id' => null,
                    'mode' => 'one_time',
                ],
            ]);
        $this->app->instance(PaymentService::class, $paymentService);

        $this->actingAs($foodie, 'api');

        $this->postJson('/api/v2/payments/intent', [
            'order_id' => $order->id,
            'payment_method_id' => 'pm_one_time_123',
        ])
            ->assertOk()
            ->assertJsonPath('data.payment_intent_id', 'pi_one_time_123')
            ->assertJsonPath('data.payment_method_id', 'pm_one_time_123')
            ->assertJsonPath('data.selection_mode', 'one_time');
    }

    public function test_foodie_can_cancel_requested_order_only_with_reason(): void
    {
        Queue::fake();
        [$foodie, $cook, $order] = $this->createOrderFixture();

        $this->actingAs($foodie, 'api');

        $this->postJson('/api/v2/updateorderstatus', [
            'order_id' => $order->id,
            'status' => Order::STATUS_CANCELLED,
            'cancel_comment' => 'Plans changed before the kitchen accepted it.',
        ])
            ->assertOk()
            ->assertJsonPath('data.status', Order::STATUS_CANCELLED)
            ->assertJsonPath('data.cancel_reason.comment', 'Plans changed before the kitchen accepted it.');

        $this->assertDatabaseHas('cancel_reasons', [
            'order_id' => $order->id,
            'ref_id' => $foodie->id,
            'comment' => 'Plans changed before the kitchen accepted it.',
            'by_user' => 'customer',
        ]);
    }

    public function test_order_creation_can_initialize_payment_atomically(): void
    {
        DB::table('roles')->updateOrInsert(['id' => 2], [
            'role' => 'Restaurant',
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        DB::table('roles')->updateOrInsert(['id' => 3], [
            'role' => 'Foodie',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $cook = User::query()->create([
            'first_name' => 'Cook',
            'last_name' => 'Atomic',
            'email' => 'cook-atomic@example.test',
            'password' => Hash::make('password123'),
            'role_id' => 2,
            'phone' => '1111111111',
            'address' => 'Cook Street',
            'email_verified' => 1,
        ]);
        $foodie = User::query()->create([
            'first_name' => 'Foodie',
            'last_name' => 'Atomic',
            'email' => 'foodie-atomic@example.test',
            'password' => Hash::make('password123'),
            'role_id' => 3,
            'phone' => '2222222222',
            'address' => 'Foodie Street',
            'email_verified' => 1,
        ]);

        DB::table('user_roles')->insert([
            [
                'user_id' => $cook->id,
                'role_id' => 2,
                'status' => UserRole::STATUS_ACTIVE,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'user_id' => $foodie->id,
                'role_id' => 3,
                'status' => UserRole::STATUS_ACTIVE,
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);

        $kitchen = Mikitchn::query()->create([
            'user_id' => $cook->id,
            'name' => 'Atomic Kitchen',
            'address' => 'Kitchen Street',
            'phone' => '1234567890',
            'no_of_seats' => 10,
            'timings' => '{}',
            'status' => 1,
            'dine_in' => 0,
            'take_away' => 1,
        ]);

        $foodId = DB::table('foods')->insertGetId([
            'restaurant_id' => $kitchen->id,
            'food_name' => 'Atomic Dish',
            'pictures' => '[]',
            'price' => 18,
            'cookingstyle' => 1,
            'specialDiet' => '[]',
            'description' => 'Dish',
            'status' => 1,
            'dine_in' => 0,
            'take_away' => 1,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $paymentService = Mockery::mock(PaymentService::class);
        $paymentService->shouldReceive('initializeOrderPaymentIntent')
            ->once()
            ->withArgs(function (Order $order, User $user, ?string $cardReference, ?string $paymentMethodId) use ($foodie): bool {
                return (int) $order->user_id === (int) $foodie->id
                    && (int) $user->id === (int) $foodie->id
                    && $cardReference === '15'
                    && $paymentMethodId === null;
            })
            ->andReturn([
                'payment' => null,
                'selection' => ['mode' => 'saved_card'],
            ]);
        $this->app->instance(PaymentService::class, $paymentService);

        $accountProfileService = Mockery::mock(AccountProfileService::class);
        $accountProfileService->shouldReceive('ensureStripeAccountForRole')
            ->once()
            ->withArgs(function (User $user, int $roleId) use ($foodie): bool {
                return (int) $user->id === (int) $foodie->id && $roleId === 3;
            })
            ->andReturn(null);
        $this->app->instance(AccountProfileService::class, $accountProfileService);

        $this->actingAs($foodie, 'api');

        $this->postJson('/api/v2/account/orders', [
            'kitchen_id' => $kitchen->id,
            'delivery_date' => now()->addDay()->format('Y-m-d'),
            'delivery_time_from' => '12:00',
            'delivery_time_to' => '13:00',
            'taxes' => '1.80',
            'dine_in' => 0,
            'take_away' => 1,
            'item_data' => json_encode([
                ['id' => $foodId, 'quantity' => 1],
            ]),
            'card_id' => '15',
        ])
            ->assertOk()
            ->assertJsonPath('data.order_id', 1);
    }

    public function test_foodie_cannot_cancel_order_after_it_has_been_accepted(): void
    {
        Queue::fake();
        [$foodie, $cook, $order] = $this->createOrderFixture([
            'status' => Order::STATUS_CONFIRMED,
            'paid' => 1,
        ]);

        $this->actingAs($foodie, 'api');

        $this->postJson('/api/v2/updateorderstatus', [
            'order_id' => $order->id,
            'status' => Order::STATUS_CANCELLED,
            'cancel_comment' => 'Trying too late.',
        ])
            ->assertStatus(422)
            ->assertJsonPath(
                'isError',
                'miFoodi can only cancel an order before it is accepted by miCook.'
            );

        $this->assertDatabaseMissing('cancel_reasons', [
            'order_id' => $order->id,
            'comment' => 'Trying too late.',
        ]);
        $this->assertDatabaseHas('orders', [
            'id' => $order->id,
            'status' => Order::STATUS_CONFIRMED,
        ]);
    }

    public function test_order_status_cannot_be_reverted_back_to_requested(): void
    {
        [$foodie, $cook, $order] = $this->createOrderFixture([
            'status' => Order::STATUS_CONFIRMED,
            'paid' => 1,
        ]);

        $this->actingAs($foodie, 'api');

        $this->postJson('/api/v2/updateorderstatus', [
            'order_id' => $order->id,
            'status' => Order::STATUS_REQUESTED,
        ])
            ->assertStatus(422)
            ->assertJsonPath('isError', 'Order status cannot be moved back to requested.');
    }

    public function test_payment_method_form_rejects_untrusted_return_url(): void
    {
        $this->get('/api/v2/payments/payment-method-entry?mode=one_time&return_url=' . urlencode('https://evil.example/callback'))
            ->assertStatus(422);
    }

    /**
     * @return array{0: User, 1: User, 2: Order}
     */
    private function createOrderFixture(array $orderOverrides = []): array
    {
        DB::table('roles')->updateOrInsert(['id' => 2], [
            'role' => 'Restaurant',
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        DB::table('roles')->updateOrInsert(['id' => 3], [
            'role' => 'Foodie',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $cook = User::query()->create([
            'first_name' => 'Cook',
            'last_name' => 'Fixture',
            'email' => 'cook-' . uniqid() . '@example.test',
            'password' => Hash::make('password123'),
            'role_id' => 2,
            'phone' => '1111111111',
            'address' => 'Cook Street',
            'email_verified' => 1,
        ]);

        $foodie = User::query()->create([
            'first_name' => 'Foodie',
            'last_name' => 'Fixture',
            'email' => 'foodie-' . uniqid() . '@example.test',
            'password' => Hash::make('password123'),
            'role_id' => 3,
            'phone' => '2222222222',
            'address' => 'Foodie Street',
            'email_verified' => 1,
        ]);

        DB::table('user_roles')->insert([
            [
                'user_id' => $cook->id,
                'role_id' => 2,
                'status' => UserRole::STATUS_ACTIVE,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'user_id' => $foodie->id,
                'role_id' => 3,
                'status' => UserRole::STATUS_ACTIVE,
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);

        $kitchen = Mikitchn::query()->create([
            'user_id' => $cook->id,
            'name' => 'Fixture Kitchen',
            'address' => 'Kitchen Street',
            'phone' => '1234567890',
            'no_of_seats' => 10,
            'timings' => '{}',
            'status' => 1,
            'dine_in' => 0,
            'take_away' => 1,
        ]);

        $orderData = array_merge([
            'mikitchn_id' => $kitchen->id,
            'user_id' => $foodie->id,
            'dine_in' => 0,
            'take_away' => 1,
            'persons' => 0,
            'delivery_date' => now()->addDay()->format('Y-m-d'),
            'delivery_time_from' => '12:00:00',
            'delivery_time_to' => '12:30:00',
            'item_total_price' => 30,
            'taxes' => 3,
            'total_price' => 33,
            'status' => Order::STATUS_REQUESTED,
            'paid' => 0,
            'created_at' => now(),
            'updated_at' => now(),
        ], $orderOverrides);

        $orderId = DB::table('orders')->insertGetId($orderData);
        $order = Order::query()->findOrFail($orderId);

        return [$foodie, $cook, $order];
    }
}
