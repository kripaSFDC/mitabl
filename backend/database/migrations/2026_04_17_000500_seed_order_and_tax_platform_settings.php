<?php

use Illuminate\Database\Migrations\Migration;

return new class extends Migration
{
    public function up(): void
    {
        $settings = [
            [
                'key' => 'orders.new_customer_discount_threshold',
                'value' => json_encode(['value' => 5]),
                'value_type' => 'integer',
                'description' => 'Number of completed orders below which the new-customer discount is applied.',
            ],
            [
                'key' => 'orders.new_customer_discount_cents',
                'value' => json_encode(['value' => 5000]),
                'value_type' => 'integer',
                'description' => 'New-customer discount amount in cents (AUD). Applied when user has fewer completed orders than the threshold.',
            ],
            [
                'key' => 'tax.gst_rate',
                'value' => json_encode(['value' => 10]),
                'value_type' => 'integer',
                'description' => 'GST rate as a whole-number percentage (e.g. 10 = 10%).',
            ],
        ];

        foreach ($settings as $setting) {
            \App\Models\PlatformSetting::query()->updateOrCreate(
                ['key' => $setting['key']],
                $setting
            );
        }
    }

    public function down(): void
    {
        \App\Models\PlatformSetting::query()
            ->whereIn('key', [
                'orders.new_customer_discount_threshold',
                'orders.new_customer_discount_cents',
                'tax.gst_rate',
            ])
            ->delete();
    }
};
