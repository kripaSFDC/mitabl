<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\SpecialDiet;
use Illuminate\Support\Facades\Schema;

class SpecialDietsSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {
        Schema::disableForeignKeyConstraints();
        try {
            SpecialDiet::truncate();
        } finally {
            Schema::enableForeignKeyConstraints();
        }

        $specialDiet =  [
            [
              'name' => 'Vegan'
            ],
            [
              'name' => 'Gluten Free'
            ],
            [
              'name' => 'Halal'
            ],
            [
              'name' => 'Kosher'
            ],
            [
              'name' => 'Contains Dairy'
            ],
            [
              'name' => 'Spicy'
            ],
            [
              'name' => 'Contains Tree nut and/or peanut'
            ],
            [
              'name' => 'Contains Fish and/or shellfish'
            ]
          ];

          SpecialDiet::insert($specialDiet);
    }
}
