<?php

namespace Tests\Feature;

use App\Models\Mikitchn;
use App\Models\Order;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Notification;
use RuntimeException;
use Tests\TestCase;

class AdminNotificationFailureResilienceTest extends TestCase
{
    use RefreshDatabase;

    public function test_kitchen_status_update_survives_mail_and_notification_failures(): void
    {
        Notification::shouldReceive('send')
            ->atLeast()->once()
            ->andThrow(new RuntimeException('Push unavailable'));
        Mail::shouldReceive('to->queue')
            ->once()
            ->andThrow(new RuntimeException('SMTP unavailable'));

        $user = User::query()->create([
            'role_id' => 2,
            'first_name' => 'Cook',
            'last_name' => 'One',
            'email' => 'cook@example.test',
            'password' => bcrypt('password123'),
            'phone' => '1234567890',
            'address' => 'Cook address',
        ]);

        $kitchen = Mikitchn::query()->create([
            'user_id' => $user->id,
            'name' => 'Kitchen One',
            'address' => 'Kitchen address',
            'phone' => '1234567890',
            'latitude' => 24.7,
            'longitude' => 46.7,
            'status' => 0,
            'open' => 1,
        ]);

        $kitchen->update(['status' => 1]);

        $this->assertSame(1, (int) $kitchen->fresh()->status);
    }

    public function test_order_status_update_survives_mail_and_notification_failures(): void
    {
        Notification::shouldReceive('send')
            ->atLeast()->once()
            ->andThrow(new RuntimeException('Push unavailable'));
        Mail::shouldReceive('to->queue')
            ->twice()
            ->andThrow(new RuntimeException('SMTP unavailable'));

        $customer = User::query()->create([
            'role_id' => 3,
            'first_name' => 'Customer',
            'last_name' => 'One',
            'email' => 'customer@example.test',
            'password' => bcrypt('password123'),
            'phone' => '1234567891',
            'address' => 'Customer address',
        ]);

        $cook = User::query()->create([
            'role_id' => 2,
            'first_name' => 'Cook',
            'last_name' => 'Two',
            'email' => 'cook2@example.test',
            'password' => bcrypt('password123'),
            'phone' => '1234567892',
            'address' => 'Cook address',
        ]);

        $kitchen = Mikitchn::query()->create([
            'user_id' => $cook->id,
            'name' => 'Kitchen Two',
            'address' => 'Kitchen address',
            'phone' => '1234567892',
            'latitude' => 24.7,
            'longitude' => 46.7,
            'status' => 1,
            'open' => 1,
        ]);

        $order = Order::query()->create([
            'mikitchn_id' => $kitchen->id,
            'user_id' => $customer->id,
            'dine_in' => 0,
            'take_away' => 1,
            'persons' => 1,
            'delivery_date' => now()->toDateString(),
            'delivery_time_from' => now()->format('H:i:s'),
            'delivery_time_to' => now()->addHour()->format('H:i:s'),
            'item_total_price' => 10,
            'taxes' => 1,
            'total_price' => 11,
            'paymentmethod_id' => 1,
        ]);

        $order->status = Order::STATUS_COMPLETED;
        $order->save();

        $this->assertSame(Order::STATUS_COMPLETED, (int) $order->fresh()->status);
    }
}
