<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\CookingStyles;

class CookingStyles extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {
        CookingStyles::truncate();

        $cookingStyles =  [
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
            ],
          ];

          CookingStyles::insert($cookingStyles);
    }
}







