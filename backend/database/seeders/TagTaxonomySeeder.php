<?php

namespace Database\Seeders;

use App\Models\Tag;
use Illuminate\Database\Seeder;

class TagTaxonomySeeder extends Seeder
{
    public function run(): void
    {
        $tags = [
            ['name' => 'fraud_risk', 'description' => 'Potential fraud signal; requires additional verification.'],
            ['name' => 'vip', 'description' => 'High-value or high-priority customer/account.'],
            ['name' => 'repeat_issue', 'description' => 'Recurring issue pattern observed for this entity.'],
            ['name' => 'compliance_review', 'description' => 'Needs compliance or policy review.'],
            ['name' => 'payment_sensitive', 'description' => 'Contains payment escalation or refund sensitivity.'],
        ];

        foreach ($tags as $tag) {
            Tag::query()->firstOrCreate(['name' => $tag['name']], $tag);
        }
    }
}
