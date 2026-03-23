<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\SpecialDiet;

class SpecialDietsSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {
        \DB::statement('SET FOREIGN_KEY_CHECKS=0;');
        SpecialDiet::truncate();
        \DB::statement('SET FOREIGN_KEY_CHECKS=1;');

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
