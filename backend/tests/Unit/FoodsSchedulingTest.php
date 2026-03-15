<?php

namespace Tests\Unit;

use App\Models\Foods;
use Carbon\Carbon;
use Tests\TestCase;

class FoodsSchedulingTest extends TestCase
{
    public function test_is_scheduled_for_returns_true_when_no_schedule_constraints_are_set(): void
    {
        $food = new Foods();

        $this->assertTrue($food->isScheduledFor(Carbon::parse('2026-03-16')));
    }

    public function test_is_scheduled_for_rejects_mismatched_specific_date(): void
    {
        $food = new Foods([
            'available_date' => '2026-03-21',
        ]);

        $this->assertFalse($food->isScheduledFor(Carbon::parse('2026-03-20')));
        $this->assertTrue($food->isScheduledFor(Carbon::parse('2026-03-21')));
    }

    public function test_is_scheduled_for_rejects_day_not_in_recurring_days(): void
    {
        $food = new Foods([
            'available_days' => [1, 3, 5],
        ]);

        $this->assertFalse($food->isScheduledFor(Carbon::parse('2026-03-22'))); // Sunday
        $this->assertTrue($food->isScheduledFor(Carbon::parse('2026-03-23'))); // Monday
    }

    public function test_is_scheduled_for_validates_requested_window_within_available_range(): void
    {
        $food = new Foods([
            'available_from_time' => '10:00',
            'available_to_time' => '14:00',
        ]);

        $deliveryDate = Carbon::parse('2026-03-23');

        $this->assertTrue($food->isScheduledFor($deliveryDate, '11:00', '13:00'));
        $this->assertFalse($food->isScheduledFor($deliveryDate, '09:00', '11:00'));
        $this->assertFalse($food->isScheduledFor($deliveryDate, '11:00', null));
    }

    public function test_is_scheduled_for_allows_time_agnostic_query_when_food_has_time_window(): void
    {
        $food = new Foods([
            'available_from_time' => '10:00',
            'available_to_time' => '14:00',
        ]);

        $this->assertTrue($food->isScheduledFor(Carbon::parse('2026-03-23')));
    }

    public function test_query_scopes_apply_expected_filters(): void
    {
        $query = Foods::query()
            ->active()
            ->forRestaurant(12)
            ->searchTerm('pizza')
            ->availableForOrderType(1, 0);

        $sql = $query->toSql();

        $this->assertStringContainsString('"status" = ?', $sql);
        $this->assertStringContainsString('"restaurant_id" = ?', $sql);
        $this->assertStringContainsString('"food_name" like ?', $sql);
        $this->assertStringContainsString('"dine_in" = ?', $sql);
        $this->assertStringContainsString('"take_away" = ?', $sql);
        $this->assertSame([1, 12, '%pizza%', '%pizza%', 1, 0], $query->getBindings());
    }

    public function test_search_term_scope_does_not_change_query_when_term_is_empty(): void
    {
        $query = Foods::query()->searchTerm('   ');

        $this->assertStringNotContainsString('like', strtolower($query->toSql()));
    }

    public function test_added_images_accessor_returns_relation_value(): void
    {
        $food = new Foods();
        $food->setRelation('addedimage', collect([(object) ['id' => 99]]));

        $images = $food->added_images;

        $this->assertCount(1, $images);
        $this->assertSame(99, $images->first()->id);
    }

}
