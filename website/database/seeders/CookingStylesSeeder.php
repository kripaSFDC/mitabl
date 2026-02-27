<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\CookingStyles;

class CookingStylesSeeder extends Seeder
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
              'name' => 'Italian'
            ],
            [
              'name' => 'Thai'
            ],
            [
              'name' => 'French'
            ],
            [
              'name' => 'Japanese'
            ],[
              'name' => 'Lebanese'
            ],[
              'name' => 'Spanish'
            ],[
              'name' => 'German'
            ],[
              'name' => 'Korean'
            ],[
              'name' => 'Caribbean'
            ],[
              'name' => 'Greek'
            ],[
              'name' => 'Filipino'
            ],[
              'name' => 'Indian'
            ],[
              'name' => 'Mexican'
            ],[
              'name' => 'Indonesian'
            ],[
              'name' => 'Brazilian'
            ],[
              'name' => 'Chinese'
            ],[
              'name' => 'American'
            ],[
              'name' => 'African'
            ],[
              'name' => 'Malaysian'
            ],[
              'name' => 'Irish'
            ],[
              'name' => 'Turkish'
            ],[
              'name' => 'Israeli'
            ],[
              'name' => 'Others'
            ]
          ];

          CookingStyles::insert($cookingStyles);
    }
}
